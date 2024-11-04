const std = @import("std");

test "filter enum" {
    const alloc = std.testing.allocator;

    const Filter = struct {
        filter: FilterContent,

        const FilterContent = struct {
            @"and": []AndFilter,
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

    const expected =
        \\{
        \\  "filter": {
        \\    "and": [
        \\      {
        \\        "property": "Date",
        \\        "date": {
        \\          "equals": "2021-01-01"
        \\        }
        \\      },
        \\      {
        \\        "property": "Title",
        \\        "rich_text": {
        \\          "contains": "John"
        \\        }
        \\      }
        \\    ]
        \\  }
        \\}
    ;
}
