const std = @import("std");
const base64 = @import("base64");
const allocator = std.heap.page_allocator;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);

var stdin_buffer: [1024]u8 = undefined;
var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);

pub fn main() !void {
    try stdout_writer.interface.print("Base64 Encoder/Decoder\n", .{});
    try stdout_writer.interface.print("Enter your input. Maximum size is 1024 bytes.\n", .{});
    try stdout_writer.interface.print("Press Ctrl+D (Unix) or Ctrl+Z (Windows) to exit.\n\n", .{});
    try stdout_writer.interface.flush();

    while (true) {
        try stdout_writer.interface.print("Input: ", .{});
        try stdout_writer.interface.flush();

        const input = stdin_reader.interface.takeDelimiterExclusive('\n') catch |err| {
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
                error.InvalidLength => "Input length is not valid for Base64 decoding.",
                error.OutOfMemory => return err,
            };
            break :blk try std.fmt.allocPrint(allocator, "<Decoding failed: {s}>", .{err_msg});
        };
        defer allocator.free(decoded);

        try stdout_writer.interface.print("Encoded: {s}\n", .{encoded});
        try stdout_writer.interface.print("Decoded: {s}\n", .{decoded});
        try stdout_writer.interface.print("----------\n", .{});
        try stdout_writer.interface.flush();
    }
}
