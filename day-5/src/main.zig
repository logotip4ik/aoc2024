const std = @import("std");

const string = []const u8;
const print = std.debug.print;
const Rules = std.AutoHashMap(u16, []u16);

fn contains(comptime T: type, arr: []T, chunk: T) bool {
    for (arr) |item| {
        if (item == chunk) {
            return true;
        }
    }

    return false;
}

fn isInOrder(updates: []u16, rules: *Rules) bool {
    for (updates, 0..) |update, i| {
        const maybeRule = rules.get(update);

        if (maybeRule) |toBeAfterKey| {
            for (toBeAfterKey) |rule| {
                const ruleKeyInArray = std.mem.indexOfScalar(u16, updates, rule);

                if (ruleKeyInArray != null and ruleKeyInArray.? < i) {
                    return false;
                }
            }
        } else {
            continue;
        }
    }

    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input =
    //     \\47|53
    //     \\97|13
    //     \\97|61
    //     \\97|47
    //     \\75|29
    //     \\61|13
    //     \\75|53
    //     \\29|13
    //     \\97|29
    //     \\53|29
    //     \\61|53
    //     \\97|53
    //     \\61|29
    //     \\47|13
    //     \\75|47
    //     \\97|75
    //     \\47|61
    //     \\75|61
    //     \\47|29
    //     \\75|13
    //     \\53|13
    //     \\
    //     \\75,47,61,53,29
    //     \\97,61,53,29,13
    //     \\75,29,13
    //     \\75,97,47,61,53
    //     \\61,13,29
    //     \\97,13,75,29,47
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var rules = Rules.init(alloc);
    defer {
        var valueIter = rules.valueIterator();
        while (valueIter.next()) |valuePtr| {
            alloc.free(valuePtr.*);
        }

        rules.deinit();
    }

    var parsedRules = false;
    var lineIter = std.mem.splitSequence(u8, input, "\n");
    var sum: u32 = 0;
    while (lineIter.next()) |line| {
        if (line.len == 0) {
            parsedRules = true;
            continue;
        }

        if (!parsedRules) {
            const key = try std.fmt.parseInt(u16, line[0..2], 10);
            const value = try std.fmt.parseInt(u16, line[3..], 10);

            const gop = try rules.getOrPut(key);
            if (gop.found_existing) {
                const itemsCopy = try alloc.realloc(gop.value_ptr.*, gop.value_ptr.len + 1);
                itemsCopy[itemsCopy.len - 1] = value;

                gop.value_ptr.* = itemsCopy;
            } else {
                const items = try alloc.alloc(u16, 1);
                items[0] = value;

                gop.key_ptr.* = key;
                gop.value_ptr.* = items;
            }
        } else {
            const numberOfItems = std.mem.count(u8, line, ",") + 1;
            var items = try std.ArrayList(u16).initCapacity(alloc, numberOfItems);
            defer items.deinit();

            var itemIter = std.mem.splitSequence(u8, line, ",");
            while (itemIter.next()) |item| {
                items.appendAssumeCapacity(
                    try std.fmt.parseInt(u16, item, 10),
                );
            }

            if (isInOrder(items.items, &rules)) {
                const middleItem = items.items[items.items.len / 2];
                sum += middleItem;
            }
        }
    }

    print("sum {}\n", .{sum});
}
