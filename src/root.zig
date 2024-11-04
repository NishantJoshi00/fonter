const std = @import("std");

const builtin = @import("builtin");

const config = @import("config");

pub const NotionClient = struct {
    integration_secret: []const u8,
    database_id: []const u8,

    const NOTION_URL = "https://api.notion.com/v1";
    const Self = @This();

    pub fn from_env(env: *std.process.EnvMap) !Self {
        const integration_secret = FuncUtils.orfn([]const u8, env.get("NOTION_INTEGRATION_SECRET"), config.NOTION_INTEGRATION_SECRET) orelse return error.@"Missing NOTION_INTEGRATION_SECRET";

        const database_id = FuncUtils.orfn([]const u8, env.get("NOTION_DATABASE_ID"), config.NOTION_DATABASE_ID) orelse return error.@"Missing NOTION_DATABASE_ID";

        return Self{
            .integration_secret = integration_secret,
            .database_id = database_id,
        };
    }
    fn get_headers(self: *const Self, alloc: std.mem.Allocator) ![]std.http.Header {
        const header_value = try std.fmt.allocPrint(alloc, "Bearer {s}", .{self.integration_secret});

        const output = &[_]std.http.Header{
            .{ .name = "Authorization", .value = header_value },
            .{ .name = "Notion-Version", .value = "2022-06-28" },
            .{ .name = "Content-Type", .value = "application/json" },
        };

        return try alloc.dupe(std.http.Header, output);
    }

    fn deinit_headers(header_map: []std.http.Header, alloc: std.mem.Allocator) void {
        for (header_map) |header| {
            if (std.mem.eql(u8, header.name, "Authorization")) {
                alloc.free(header.value);
            }
        }

        alloc.free(header_map);
    }

    pub const Create = struct {
        fn get_url(_: *const Self, alloc: std.mem.Allocator) ![]const u8 {
            const query_url = try std.fmt.allocPrint(alloc, "{s}/pages", .{Self.NOTION_URL});
            return query_url;
        }

        fn get_body(self: *const Self, alloc: std.mem.Allocator) ![]const u8 {
            const Body = struct {
                parent: Parent,
                properties: Properties,

                const Parent = struct {
                    database_id: []const u8,
                };

                const Properties = struct {
                    Name: Name,
                    Date: Date,
                    Counter: Counter,

                    const Name = struct {
                        title: [1]Title,

                        const Title = struct {
                            text: Text,

                            const Text = struct {
                                content: []const u8,
                            };
                        };
                    };

                    const Date = struct {
                        date: DateInner,

                        const DateInner = struct {
                            start: []const u8,
                        };
                    };

                    const Counter = struct {
                        number: i64,
                    };
                };
            };

            const now = try today(alloc);
            defer alloc.free(now);

            const title = [1]Body.Properties.Name.Title{
                .{ .text = .{ .content = "Counter" } },
            };

            const typed_body = Body{
                .parent = .{ .database_id = self.database_id },
                .properties = .{
                    .Name = .{ .title = title },
                    .Date = .{ .date = .{ .start = now } },
                    .Counter = .{ .number = 1.0 },
                },
            };

            const json_body = try std.json.stringifyAlloc(alloc, typed_body, .{});

            return json_body;
        }

        pub fn call(self: *const Self, client: *std.http.Client, alloc: std.mem.Allocator) !void {
            const url = try Self.Create.get_url(self, alloc);
            defer alloc.free(url);

            const headers = try Self.get_headers(self, alloc);
            defer Self.deinit_headers(headers, alloc);

            const body = try Self.Create.get_body(self, alloc);
            defer alloc.free(body);

            const response = try client.fetch(.{
                .method = .POST,
                .location = .{ .url = url },
                .extra_headers = headers,
                .payload = body,
            });

            std.debug.assert(response.status == .ok);
        }
    };

    pub const Update = struct {
        fn get_url(_: *const Self, alloc: std.mem.Allocator, page_id: []const u8) ![]const u8 {
            const query_url = try std.fmt.allocPrint(alloc, "{s}/pages/{s}", .{ Self.NOTION_URL, page_id });
            return query_url;
        }

        fn get_body(_: *const Self, alloc: std.mem.Allocator, counter: i64) ![]const u8 {
            const Body = struct {
                properties: Properties,

                const Properties = struct {
                    Counter: Counter,

                    const Counter = struct {
                        number: i64,
                    };
                };
            };

            const typed_body = Body{
                .properties = .{
                    .Counter = .{ .number = counter },
                },
            };

            const json_body = try std.json.stringifyAlloc(alloc, typed_body, .{});

            return json_body;
        }

        pub fn call(self: *const Self, client: *std.http.Client, alloc: std.mem.Allocator, counter: i64, page_id: []const u8) !void {
            const url = try Self.Update.get_url(self, alloc, page_id);
            defer alloc.free(url);

            const headers = try Self.get_headers(self, alloc);
            defer Self.deinit_headers(headers, alloc);

            const body = try Self.Update.get_body(self, alloc, counter);
            defer alloc.free(body);

            const response = try client.fetch(.{
                .method = .PATCH,
                .location = .{ .url = url },
                .extra_headers = headers,
                .payload = body,
            });

            std.debug.assert(response.status == .ok);
        }
    };

    pub const Query = struct {
        fn get_url(self: *const Self, alloc: std.mem.Allocator) ![]const u8 {
            const query_url = try std.fmt.allocPrint(alloc, "{s}/databases/{s}/query", .{ Self.NOTION_URL, self.database_id });

            return query_url;
        }

        fn get_body(_: *const Self, alloc: std.mem.Allocator) ![]const u8 {
            const Filter = struct {
                filter: FilterContent,

                const FilterContent = struct {
                    @"and": [2]AndFilter,
                };

                // Instead of a union, we'll make a struct that can represent both types
                const AndFilter = struct {
                    property: []const u8,
                    // Optional fields for each type
                    date: ?struct {
                        equals: []const u8,
                    } = null,
                    rich_text: ?struct {
                        contains: []const u8,
                    } = null,
                };
            };

            const now = try today(alloc);
            defer alloc.free(now);

            const typed_body = Filter{
                .filter = .{
                    .@"and" = [2]Filter.AndFilter{
                        .{ .property = "Date", .date = .{ .equals = now } },
                        .{ .property = "Name", .rich_text = .{ .contains = "Counter" } },
                    },
                },
            };

            const json_body = try std.json.stringifyAlloc(alloc, typed_body, .{ .emit_null_optional_fields = false });

            return json_body;
        }

        pub fn call(self: *const Self, client: *std.http.Client, alloc: std.mem.Allocator) ![]const u8 {
            const url = try Self.Query.get_url(self, alloc);
            defer alloc.free(url);

            const headers = try Self.get_headers(self, alloc);
            defer Self.deinit_headers(headers, alloc);

            const body = try Self.Query.get_body(self, alloc);
            defer alloc.free(body);

            var response_arraylist = std.ArrayList(u8).init(alloc);

            const response = try client.fetch(.{
                .method = .POST,
                .location = .{ .url = url },
                .extra_headers = headers,
                .payload = body,
                .response_storage = .{ .dynamic = &response_arraylist },
            });

            const result = try response_arraylist.toOwnedSlice();

            std.debug.assert(response.status == .ok);

            return result;
        }

        pub const Response = struct {
            object: []const u8,
            results: []Page,

            pub const Page = struct {
                object: []const u8,
                id: []const u8,
                properties: Properties,
            };

            pub const Properties = struct {
                Date: Date,
                Counter: Counter,
            };

            pub const Date = struct {
                date: DateInner,

                const DateInner = struct {
                    start: []const u8,
                };
            };

            pub const Counter = struct {
                number: i64,
            };
        };
    };
};

pub fn today(alloc: std.mem.Allocator) ![]const u8 {
    // Safety: The code that lies after this block is tested.
    if (builtin.is_test) {
        return try alloc.dupe(u8, "2000-07-12");
    }

    const ts = std.time.timestamp();
    const seconds = @as(u64, @intCast(ts));

    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = seconds };
    const epoch_day = epoch_seconds.getEpochDay();
    const day_and_year = epoch_day.calculateYearDay();
    const month_and_day = day_and_year.calculateMonthDay();

    const date = try std.fmt.allocPrint(alloc, "{d:0>4}-{d:0>2}-{d:0>2}", .{ day_and_year.year, month_and_day.month.numeric(), month_and_day.day_index + 1 });

    return date;
}

test "today" {
    const allocator = std.testing.allocator;
    const date = try today(allocator);

    defer allocator.free(date);

    try std.testing.expectEqualStrings("2000-07-12", date);
}

test "NotionClient.Query.url" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const url = try NotionClient.Query.get_url(&client, allocator);
    defer allocator.free(url);

    try std.testing.expectEqualStrings("https://api.notion.com/v1/databases/id/query", url);
}

test "NotionClient.Query.headers" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const headers = try NotionClient.get_headers(&client, allocator);
    defer NotionClient.deinit_headers(headers, allocator);

    for (headers) |header| {
        if (std.mem.eql(u8, header.name, "Authorization")) {
            try std.testing.expectEqualStrings("Bearer secret", header.value);
        } else if (std.mem.eql(u8, header.name, "Notion-Version")) {
            try std.testing.expectEqualStrings("2022-06-28", header.value);
        } else if (std.mem.eql(u8, header.name, "Content-Type")) {
            try std.testing.expectEqualStrings("application/json", header.value);
        } else {
            try std.testing.expect(false);
        }
    }
}

test "NotionClient.Query.body" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const body = try NotionClient.Query.get_body(&client, allocator);
    defer allocator.free(body);

    const expected = "{\"filter\":{\"and\":[{\"property\":\"Date\",\"date\":{\"equals\":\"2000-07-12\"}},{\"property\":\"Name\",\"rich_text\":{\"contains\":\"Counter\"}}]}}";
    try std.testing.expectEqualStrings(expected, body);
}

test "NotionClient.Query.call" {
    const allocator = std.heap.page_allocator;
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var env_map = try std.process.getEnvMap(std.heap.page_allocator);
    defer env_map.deinit();

    const notion_client = NotionClient.from_env(&env_map) catch return error.SkipZigTest;

    const response = try NotionClient.Query.call(&notion_client, &client, allocator);

    const parsed_response = try std.json.parseFromSlice(NotionClient.Query.Response, allocator, response, .{ .ignore_unknown_fields = true });
    defer parsed_response.deinit();

    try std.testing.expectEqualStrings("list", parsed_response.value.object);
    try std.testing.expectEqual(1, parsed_response.value.results.len);
    try std.testing.expectEqualStrings("2000-07-12", parsed_response.value.results[0].properties.Date.date.start);
    try std.testing.expectEqual(0, parsed_response.value.results[0].properties.Counter.number);
    try std.testing.expectEqualStrings("page", parsed_response.value.results[0].object);
}

test "NotionClient.Create.url" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const url = try NotionClient.Create.get_url(&client, allocator);
    defer allocator.free(url);

    try std.testing.expectEqualStrings("https://api.notion.com/v1/pages", url);
}

test "NotionClient.Create.body" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const body = try NotionClient.Create.get_body(&client, allocator);
    defer allocator.free(body);

    const expected = "{\"parent\":{\"database_id\":\"id\"},\"properties\":{\"Name\":{\"title\":[{\"text\":{\"content\":\"Counter\"}}]},\"Date\":{\"date\":{\"start\":\"2000-07-12\"}},\"Counter\":{\"number\":1}}}";

    try std.testing.expectEqualStrings(expected, body);
}

test "NotionClient.Update.url" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const url = try NotionClient.Update.get_url(&client, allocator, "123");
    defer allocator.free(url);

    try std.testing.expectEqualStrings("https://api.notion.com/v1/pages/123", url);
}

test "NotionClient.Update.body" {
    const allocator = std.testing.allocator;
    const client = NotionClient{ .integration_secret = "secret", .database_id = "id" };

    const body = try NotionClient.Update.get_body(&client, allocator, 2.0);
    defer allocator.free(body);

    const expected = "{\"properties\":{\"Counter\":{\"number\":2}}}";

    try std.testing.expectEqualStrings(expected, body);
}

test "NotionClient.Update.call" {
    const allocator = std.heap.page_allocator;
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var env_map = try std.process.getEnvMap(std.heap.page_allocator);
    defer env_map.deinit();

    const notion_client = NotionClient.from_env(&env_map) catch return error.SkipZigTest;

    const query_response = try NotionClient.Query.call(&notion_client, &client, allocator);

    const parsed_query_response = try std.json.parseFromSlice(NotionClient.Query.Response, allocator, query_response, .{ .ignore_unknown_fields = true });

    const page_id = parsed_query_response.value.results[0].id;

    _ = try NotionClient.Update.call(&notion_client, &client, allocator, 0, page_id);
}

const FuncUtils = struct {
    fn orfn(comptime T: type, a: ?T, b: ?T) ?T {
        if (a) |inner_a| {
            return inner_a;
        } else {
            return b;
        }
    }
};
