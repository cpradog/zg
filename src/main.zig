const std = @import("std");

// const GraphemeIterator = @import("ziglyph").GraphemeIterator;
const GraphemeIterator = @import("Grapheme").GraphemeIterator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "lang_mix.txt", std.math.maxInt(u32));
    defer allocator.free(input);

    var result: usize = 0;
    var iter = GraphemeIterator.init(input);

    var timer = try std.time.Timer.start();

    // for (0..50) |_| {
    while (iter.next()) |_| result += 1;
    iter.cp_iter.i = 0;
    // }

    std.debug.print("result: {}, took: {}\n", .{ result, timer.lap() / std.time.ns_per_ms });
}
