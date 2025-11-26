const std = @import("std");
const base64 = @import("base64");
const allocator = std.heap.page_allocator;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    try stdout.print("Base64 Encoder/Decoder\n", .{});
    try stdout.print("Enter your input. Maximum size is 1024 bytes.\n", .{});
    try stdout.print("Press Ctrl+D (Unix) or Ctrl+Z (Windows) to exit.\n\n", .{});
    try stdout.flush();

    while (true) {
        try stdout.print("Input: ", .{});
        try stdout.flush();

        const input = stdin.takeDelimiterExclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => {
                    std.debug.print("\nEnd of input detected. Exiting.\n", .{});
                    break;
                },
                error.ReadFailed => {
                    std.debug.print("Error reading input. Exiting.\n", .{});
                    break;
                },
                error.StreamTooLong => {
                    std.debug.print("Input too long. Please limit to 1024 bytes.\n", .{});
                    // Discard the rest of the line
                    while (true) {
                        const ch = try stdin.takeByte();
                        if (ch == '\n') break;
                    }
                    continue;
                },
            }
        };

        const encoded = try base64.encode(input, allocator);
        defer allocator.free(encoded);

        const decoded = base64.decode(input, allocator) catch |err| blk: {
            const err_msg = switch (err) {
                error.InvalidCharacter => "Input contains invalid Base64 characters.",
                error.InvalidPadding => "Input has incorrect padding.",
                error.InvalidLength => "Input length (after trimming) is not valid for Base64 decoding.",
                error.OutOfMemory => return err,
            };
            break :blk try std.fmt.allocPrint(allocator, "<Decoding failed: {s}>", .{err_msg});
        };
        defer allocator.free(decoded);

        try stdout.print("Encoded: {s}\n", .{encoded});
        try stdout.print("Decoded: {s}\n", .{decoded});
        try stdout.print("----------\n", .{});
        try stdout.flush();
    }
}
