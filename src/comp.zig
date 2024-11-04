const std = @import("std");
const clap = @import("clap");

pub const Help = struct {
    pub const help =
        \\Usage: f-counter [OPTIONS]
        \\  -h, --help, +help           Print this help message.
        \\  -v, --version, +version     Print the version of the CLI tool.
        \\  +show-date                  Show today's date.
        \\  +show-counter               Show today's counter.
        \\  +incr                       Increment today's counter.
        \\
    ;

    pub fn run(_: std.mem.Allocator) !u8 {
        try std.io.getStdOut().writeAll(help);
        return 0;
    }
};

pub const Completion = struct {
    pub fn run(alloc: std.mem.Allocator) !u8 {
        const params = comptime clap.parseParamsComptime(Help.help);

        var diag = clap.Diagnostic{};
        var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
            .diagnostic = &diag,
            .allocator = alloc,
        }) catch |err| {
            // Report useful error and exit
            diag.report(std.io.getStdErr().writer(), err) catch {};
            return err;
        };
        defer res.deinit();
    }
};
