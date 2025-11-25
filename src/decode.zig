const std = @import("std");
const table = @import("table.zig");

const DecodeError = error{
    InvalidLength,
    InvalidPadding,
    InvalidCharacter,
};

/// Helpers to get the index of a base64 character, or return an error if invalid.
fn getIndex(c: u8) DecodeError!u8 {
    return table.getTableIndex(c) orelse return DecodeError.InvalidCharacter;
}

pub fn decode(input: []const u8, allocator: std.mem.Allocator) (DecodeError || std.mem.Allocator.Error)![]u8 {
    // Ignore trailing padding characters
    const input_len = blk: {
        var len = input.len;
        while (len > 0) {
            if (input[len - 1] == '=') {
                len -= 1;
            } else {
                break;
            }
        }
        break :blk len;
    };
    const trailing_len = input.len - input_len;

    // Group input into chunks of 4 base64 characters
    const num_chunks = input_len / 4;
    const remainder_len = input_len % 4;

    const output_len = switch (remainder_len) {
        0 => 3 * num_chunks,
        // Only one base64 char, not enough to form a byte
        1 => return DecodeError.InvalidLength,
        2 => blk: {
            // Need at least 2 padding characters
            if (trailing_len < 2) return DecodeError.InvalidPadding;
            // Two base64 chars -> 1 output byte
            break :blk 3 * num_chunks + 1;
        },
        3 => blk: {
            // Need at least 1 padding character
            if (trailing_len < 1) return DecodeError.InvalidPadding;
            // Three base64 chars -> 2 output bytes
            break :blk 3 * num_chunks + 2;
        },
        else => unreachable,
    };
    var output = try allocator.alloc(u8, output_len);
    errdefer allocator.free(output); // Free output buffer on error

    for (0..num_chunks) |i| {
        for (0..4) |j| {
            const c = input[i * 4 + j];
            if (c == table.PAD_CHAR) {
                // Padding character in the middle of input is invalid
                return DecodeError.InvalidPadding;
            }
        }

        const b0 = try getIndex(input[i * 4 + 0]);
        const b1 = try getIndex(input[i * 4 + 1]);
        const b2 = try getIndex(input[i * 4 + 2]);
        const b3 = try getIndex(input[i * 4 + 3]);

        output[i * 3 + 0] = (b0 << 2) | (b1 >> 4);
        output[i * 3 + 1] = (b1 << 4) | (b2 >> 2);
        output[i * 3 + 2] = (b2 << 6) | b3;
    }

    switch (remainder_len) {
        0 => {},
        2 => {
            const b0 = try getIndex(input[num_chunks * 4 + 0]);
            const b1 = try getIndex(input[num_chunks * 4 + 1]);

            output[num_chunks * 3 + 0] = (b0 << 2) | (b1 >> 4);
        },
        3 => {
            const b0 = try getIndex(input[num_chunks * 4 + 0]);
            const b1 = try getIndex(input[num_chunks * 4 + 1]);
            const b2 = try getIndex(input[num_chunks * 4 + 2]);

            output[num_chunks * 3 + 0] = (b0 << 2) | (b1 >> 4);
            output[num_chunks * 3 + 1] = (b1 << 4) | (b2 >> 2);
        },
        else => unreachable,
    }

    return output;
}

fn testDecode(input: []const u8, expected_output: []const u8) !void {
    const allocator = std.testing.allocator;

    const encoded = try decode(input, allocator);
    defer allocator.free(encoded);

    try std.testing.expect(std.mem.eql(u8, encoded, expected_output));
}

test "base64 decode function" {
    const cases: [10][2][]const u8 = .{
        .{ "", "" },
        .{ "a", "YQ==" },
        .{ "aa", "YWE=" },
        .{ "aaa", "YWFh" },
        .{ "aaaa", "YWFhYQ==" },
        .{ "aaaaa", "YWFhYWE=" },
        .{ "aaaaaa", "YWFhYWFh" },
        .{ "aaaaaaa", "YWFhYWFhYQ==" },
        .{ "aaaaaaaa", "YWFhYWFhYWE=" },
        .{ "aaaaaaaaa", "YWFhYWFhYWFh" },
    };

    for (cases) |case| {
        try testDecode(case[1], case[0]);
    }
}

test "decode valid with extra padding" {
    const allocator = std.testing.allocator;
    const expected_output = try decode("Zig=", allocator);
    defer allocator.free(expected_output);

    try testDecode("Zig===", expected_output);
    try testDecode("Zig====", expected_output);
}

test "decode invalid bytes" {
    const allocator = std.testing.allocator;
    const invalid_inputs: [2][]const u8 = .{
        "Zig!",
        "Zig?",
    };
    for (invalid_inputs) |input| {
        if (decode(input, allocator)) |decoded| {
            allocator.free(decoded);
            try std.testing.expect(false);
        } else |err| {
            try std.testing.expect(err == DecodeError.InvalidCharacter);
        }
    }
}

test "decode wrong padding in middle" {
    const allocator = std.testing.allocator;
    const invalid_inputs: [4][]const u8 = .{
        "ab==cdef",
        "abcd==ef",
        "abcdef=",
        "abcdefg",
    };
    for (invalid_inputs) |input| {
        if (decode(input, allocator)) |decoded| {
            allocator.free(decoded);
            try std.testing.expect(false);
        } else |err| {
            try std.testing.expect(err == DecodeError.InvalidPadding);
        }
    }
}

test "decode invalid length" {
    const allocator = std.testing.allocator;
    const invalid_inputs: [2][]const u8 = .{
        "a",
        "abcde",
    };
    for (invalid_inputs) |input| {
        if (decode(input, allocator)) |decoded| {
            allocator.free(decoded);
            try std.testing.expect(false);
        } else |err| {
            try std.testing.expect(err == DecodeError.InvalidLength);
        }
    }
}
