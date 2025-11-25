const std = @import("std");
const table = @import("table.zig");

const TABLE = table.TABLE;
const PAD_CHAR: u8 = table.PAD_CHAR;

const MASK_6_BITS: u8 = 0b0011_1111;

pub fn encode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const num_chunks = input.len / 3;
    const remainder_len = input.len % 3;

    const output_len: usize = if (remainder_len == 0)
        num_chunks * 4
    else
        (num_chunks + 1) * 4;
    var output = try allocator.alloc(u8, output_len);

    for (0..num_chunks) |i| {
        const b0 = input[i * 3];
        const b1 = input[i * 3 + 1];
        const b2 = input[i * 3 + 2];

        output[i * 4 + 0] = TABLE[(b0 >> 2) & MASK_6_BITS];
        output[i * 4 + 1] = TABLE[((b0 << 4) | (b1 >> 4)) & MASK_6_BITS];
        output[i * 4 + 2] = TABLE[((b1 << 2) | (b2 >> 6)) & MASK_6_BITS];
        output[i * 4 + 3] = TABLE[b2 & MASK_6_BITS];
    }

    switch (remainder_len) {
        0 => {},
        1 => {
            const b0 = input[num_chunks * 3];
            output[num_chunks * 4 + 0] = TABLE[(b0 >> 2) & MASK_6_BITS];
            output[num_chunks * 4 + 1] = TABLE[(b0 << 4) & MASK_6_BITS];
            output[num_chunks * 4 + 2] = PAD_CHAR;
            output[num_chunks * 4 + 3] = PAD_CHAR;
        },
        2 => {
            const b0 = input[num_chunks * 3];
            const b1 = input[num_chunks * 3 + 1];
            output[num_chunks * 4 + 0] = TABLE[(b0 >> 2) & MASK_6_BITS];
            output[num_chunks * 4 + 1] = TABLE[((b0 << 4) | (b1 >> 4)) & MASK_6_BITS];
            output[num_chunks * 4 + 2] = TABLE[(b1 << 2) & MASK_6_BITS];
            output[num_chunks * 4 + 3] = PAD_CHAR;
        },
        else => unreachable,
    }

    return output;
}

fn testEncode(input: []const u8, expected_output: []const u8) !void {
    const allocator = std.testing.allocator;

    const encoded = try encode(input, allocator);
    defer allocator.free(encoded);

    try std.testing.expect(std.mem.eql(u8, encoded, expected_output));
}

test "base64 encode function" {
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
        try testEncode(case[0], case[1]);
    }
}
