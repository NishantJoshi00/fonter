const std = @import("std");

const cli = @import("cli.zig");

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const action = try cli.Action.detect_cli(alloc);
    return try action.runMain(alloc);
}
