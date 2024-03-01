const std = @import("std");
const builtin = @import("builtin");
const fmt = std.fmt;
const mem = std.mem;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Process DerivedEastAsianWidth.txt
    var in_file = try std.fs.cwd().openFile("data/unicode/CaseFolding.txt", .{});
    defer in_file.close();
    var in_buf = std.io.bufferedReader(in_file.reader());
    const in_reader = in_buf.reader();

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();
    _ = args_iter.skip();
    const output_path = args_iter.next() orelse @panic("No output file arg!");

    const compressor = std.compress.deflate.compressor;
    var out_file = try std.fs.cwd().createFile(output_path, .{});
    defer out_file.close();
    var out_comp = try compressor(allocator, out_file.writer(), .{ .level = .best_compression });
    defer out_comp.deinit();
    const writer = out_comp.writer();

    const endian = builtin.cpu.arch.endian();
    var line_buf: [4096]u8 = undefined;

    lines: while (try in_reader.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len == 0 or line[0] == '#') continue;

        const no_comment = if (mem.indexOfScalar(u8, line, '#')) |octo| line[0..octo] else line;

        var field_iter = mem.tokenizeSequence(u8, no_comment, "; ");
        var cps: [4]u24 = undefined;
        var len: usize = 2;

        var i: usize = 0;
        while (field_iter.next()) |field| : (i += 1) {
            switch (i) {
                0 => cps[0] = try fmt.parseInt(u24, field, 16),

                1 => {
                    if (!mem.eql(u8, field, "C") and !mem.eql(u8, field, "F")) continue :lines;
                    if (mem.eql(u8, field, "F")) len = 3;
                },

                2 => {
                    if (len == 3) {
                        // Full case fold
                        // std.debug.print("-->{s} {s}\n", .{ line, field });
                        var cp_iter = mem.tokenizeScalar(u8, field, ' ');
                        len = 1;
                        while (cp_iter.next()) |cp_str| : (len += 1) {
                            cps[len] = try fmt.parseInt(u24, cp_str, 16);
                        }
                    } else {
                        // Common case fold
                        cps[1] = try fmt.parseInt(u24, field, 16);
                    }
                },

                else => {},
            }
        }

        try writer.writeInt(u8, @intCast(len), endian);
        for (cps[0..len]) |cp| try writer.writeInt(u24, cp, endian);
    }

    try writer.writeInt(u16, 0, endian);
    try out_comp.flush();
}
