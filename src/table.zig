const std = @import("std");

/// Base64 encoding table
pub const TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
/// Base64 padding character
pub const PAD_CHAR: u8 = '=';

/// Get the index of a Base64 character in the encoding table
/// Returns null if the character is not found in the table
pub fn getTableIndex(c: u8) ?u8 {
    switch (c) {
        'A'...'Z' => return c - 'A',
        'a'...'z' => return c - 'a' + 26,
        '0'...'9' => return c - '0' + 52,
        '+' => return 62,
        '/' => return 63,
        else => return null,
    }
}

test "base64 table is correct" {
    var i: usize = 0;
    for ('A'..'Z' + 1) |c| {
        try std.testing.expect(TABLE[i] == c);
        i += 1;
    }
    for ('a'..'z' + 1) |c| {
        try std.testing.expect(TABLE[i] == c);
        i += 1;
    }
    for ('0'..'9' + 1) |c| {
        try std.testing.expect(TABLE[i] == c);
        i += 1;
    }
    try std.testing.expect(TABLE[62] == '+');
    try std.testing.expect(TABLE[63] == '/');
}

test "getTableIndex function" {
    for (0..64) |i| {
        const c = TABLE[i];
        const index = getTableIndex(c);
        try std.testing.expect(@as(usize, index.?) == i);
    }
    try std.testing.expect(getTableIndex('=') == null);
    try std.testing.expect(getTableIndex('!') == null);
}
