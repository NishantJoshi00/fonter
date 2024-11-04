const std = @import("std");

const root = @import("root.zig");
const config = @import("config");
const builtin = @import("builtin");

pub const Action = enum {
    /// Print the version of the CLI tool.
    version,
    /// Print the help message.
    help,
    /// Show today's date.
    @"show-date",
    /// Show today's counter.
    @"show-counter",
    /// Increment today's counter.
    incr,

    const Self = @This();

    pub const Error = error{
        MultipleArguments,
        InvalidArgument,
    };

    pub fn detect_cli(alloc: std.mem.Allocator) !Self {
        var arg_iter = try std.process.argsWithAllocator(alloc);
        defer arg_iter.deinit();

        var last_action: ?Self = null;

        while (arg_iter.next()) |arg| {

            // Handling CLI sanity.
            //

            if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                return .help;
            }

            if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
                return .version;
            }

            // handling invalid CLI.
            if (arg.len == 0 or arg[0] != '+') continue;
            if (last_action != null) return Error.MultipleArguments;
            last_action = std.meta.stringToEnum(Self, arg[1..]) orelse return Error.InvalidArgument;
        }

        if (last_action) |act| {
            return act;
        } else {
            return .help;
        }
    }

    pub fn runMain(self: Self, alloc: std.mem.Allocator) !u8 {
        return switch (self) {
            .version => try Version.run(alloc),
            .help => try Help.run(alloc),
            .@"show-date" => try ShowDate.run(alloc),
            .@"show-counter" => try ShowCounter.run(alloc),
            .incr => try Incr.run(alloc),
        };
    }

    const Version = struct {
        pub fn run(alloc: std.mem.Allocator) !u8 {
            const output = try std.fmt.allocPrint(alloc, "daily-counter: {s}\nzig: {}\narch: {s}", .{ "0.1.0", builtin.zig_version, builtin.target.cpu.arch.genericName() });
            defer alloc.free(output);

            try std.io.getStdOut().writeAll(output);
            return 0;
        }
    };

    const Help = struct {
        pub fn run(_: std.mem.Allocator) !u8 {
            const help =
                \\Usage: daily-counter [OPTIONS]
                \\  -h, --help, +help           Print this help message.
                \\  -v, --version, +version     Print the version of the CLI tool.
                \\  +show-date                  Show today's date.
                \\  +show-counter               Show today's counter.
                \\  +incr                       Increment today's counter.
                \\
            ;

            try std.io.getStdOut().writeAll(help);
            return 0;
        }
    };

    const ShowDate = struct {
        pub fn run(alloc: std.mem.Allocator) !u8 {
            const date = try root.today(alloc);
            defer alloc.free(date);
            const output_fmt = try std.fmt.allocPrint(alloc, "Today's date is {s}.\n", .{date});
            defer alloc.free(output_fmt);

            try std.io.getStdOut().writeAll(output_fmt);
            return 0;
        }
    };

    const ShowCounter = struct {
        pub fn run(alloc: std.mem.Allocator) !u8 {
            var env_map = try std.process.getEnvMap(alloc);
            defer env_map.deinit();

            const not_client = try root.NotionClient.from_env(&env_map);
            var htt_client = std.http.Client{ .allocator = alloc };
            defer htt_client.deinit();

            const query_response = try root.NotionClient.Query.call(&not_client, &htt_client, alloc);
            defer alloc.free(query_response);

            const parsed_query_response = try std.json.parseFromSlice(
                root.NotionClient.Query.Response,
                alloc,
                query_response,
                .{ .ignore_unknown_fields = true },
            );
            defer parsed_query_response.deinit();

            const output = parsed_query_response.value;

            const date = try root.today(alloc);
            defer alloc.free(date);

            if (output.results.len == 0) {
                try std.io.getStdOut().writeAll("No counter found for today.\n");
                return 0;
            } else {
                const counter = output.results[0].properties.Counter.number;
                const output_fmt = try std.fmt.allocPrint(alloc, "counter for {s} is {d}.\n", .{ date, counter });
                defer alloc.free(output_fmt);

                try std.io.getStdOut().writeAll(output_fmt);
                return 0;
            }
        }
    };

    const Incr = struct {
        pub fn run(alloc: std.mem.Allocator) !u8 {
            var env_map = try std.process.getEnvMap(alloc);
            defer env_map.deinit();

            const not_client = try root.NotionClient.from_env(&env_map);
            var htt_client = std.http.Client{ .allocator = alloc };
            defer htt_client.deinit();

            const query_response = try root.NotionClient.Query.call(&not_client, &htt_client, alloc);
            defer alloc.free(query_response);

            const parsed_query_response = try std.json.parseFromSlice(
                root.NotionClient.Query.Response,
                alloc,
                query_response,
                .{ .ignore_unknown_fields = true },
            );
            defer parsed_query_response.deinit();

            const date = try root.today(alloc);
            defer alloc.free(date);

            if (parsed_query_response.value.results.len == 0) {
                try root.NotionClient.Create.call(&not_client, &htt_client, alloc);

                const output_fmt = try std.fmt.allocPrint(alloc, "counter for {s} is 1.\n", .{date});
                defer alloc.free(output_fmt);

                try std.io.getStdOut().writeAll(output_fmt);
            } else {
                const counter = parsed_query_response.value.results[0].properties.Counter.number + 1;
                try root.NotionClient.Update.call(
                    &not_client,
                    &htt_client,
                    alloc,
                    counter,
                    parsed_query_response.value.results[0].id,
                );

                const output_fmt = try std.fmt.allocPrint(
                    alloc,
                    "counter for {s} is {d}.\n",
                    .{ date, counter },
                );
                defer alloc.free(output_fmt);

                try std.io.getStdOut().writeAll(output_fmt);
            }
            return 0;
        }
    };
};
