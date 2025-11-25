//! This module defines the Base64 encoding table as a constant array.
const std = @import("std");
const table = @import("table.zig");
const encoder = @import("encode.zig");
const decoder = @import("decode.zig");

const TABLE = table.TABLE;
pub const PAD_CHAR = table.PAD_CHAR;

pub const encode = encoder.encode;
pub const decode = decoder.decode;

test "base64 encode/decode roundtrip" {
    const allocator = std.testing.allocator;

    const test_data: [9][]const u8 = [9][]const u8{
        "",
        "f",
        "fo",
        "foo",
        "foob",
        "fooba",
        "foobar",
        "Hello, World!",
        "Zig is a general-purpose programming language designed for robustness, optimality, and maintainability.",
    };

    for (test_data) |data| {
        const encoded = try encode(data, allocator);
        defer allocator.free(encoded);

        const decoded = try decode(encoded, allocator);
        defer allocator.free(decoded);

        try std.testing.expect(std.mem.eql(u8, data, decoded));
    }
}

test {
    std.testing.refAllDecls(@This());
}
