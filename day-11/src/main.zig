// Not gonna lie, i was to fast to look at answers because thought that 75 shouldn't be that bat
// with array approach, but it was...
// I tried also using linked list, but that ate memory like crazy, 1.5GB after a few seconds. Then i
// got back to already stolen idea of using hashmap, that seems kinda weird for me, yet it works and
// it is very fast
const std = @import("std");

const Alloc = std.mem.Allocator;

const Stones = std.ArrayList(u64);
const StonesMap = std.AutoHashMap(u64, u64);

var buf: [1000]u8 = undefined;
fn blinkList(stones: *Stones) void {
    var i: usize = 0;
    while (i < stones.items.len) : (i += 1) {
        const stone = stones.items[i];

        if (stone == 0) {
            stones.items[i] = 1;
            continue;
        }

        const stoneString = std.fmt.bufPrint(&buf, "{d}", .{stone}) catch unreachable;
        if (stoneString.len % 2 == 0) {
            const halfOfStone = stoneString.len / 2;

            const firstNum = std.fmt.parseInt(
                u64,
                stoneString[0..halfOfStone],
                10,
            ) catch unreachable;
            const secondNum = std.fmt.parseInt(
                u64,
                stoneString[halfOfStone..stoneString.len],
                10,
            ) catch unreachable;

            stones.items[i] = firstNum;
            stones.insert(i + 1, secondNum) catch unreachable;

            // skip newly inserted item
            i += 1;
        } else {
            stones.items[i] *= 2024;
        }
    }
}

fn printMap(map: *StonesMap) void {
    std.debug.print("[\n", .{});

    var iter = map.iterator();
    while (iter.next()) |entry| {
        std.debug.print("  {} - {},\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    std.debug.print("]\n", .{});
}

fn blink(alloc: *const Alloc, map: *StonesMap, iterations: u8) u64 {
    if (iterations == 0) {
        // printMap(map);

        var sum: u64 = 0;

        var valueIter = map.valueIterator();
        while (valueIter.next()) |valuePtr| {
            sum += valuePtr.*;
        }

        return sum;
    }

    var newBlink = StonesMap.init(alloc.*);

    var iter = map.iterator();
    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        if (key == 0) {
            const got = newBlink.getOrPut(1) catch unreachable;

            if (got.found_existing) {
                got.value_ptr.* += value;
            } else {
                got.value_ptr.* = value;
            }

            continue;
        }

        const stoneString = std.fmt.bufPrint(&buf, "{d}", .{key}) catch unreachable;
        if (stoneString.len % 2 == 0) {
            const halfOfStone = stoneString.len / 2;

            const firstNum = std.fmt.parseInt(
                u64,
                stoneString[0..halfOfStone],
                10,
            ) catch unreachable;
            const secondNum = std.fmt.parseInt(
                u64,
                stoneString[halfOfStone..stoneString.len],
                10,
            ) catch unreachable;

            const firstGot = newBlink.getOrPut(firstNum) catch unreachable;
            if (firstGot.found_existing) {
                firstGot.value_ptr.* += value;
            } else {
                firstGot.value_ptr.* = value;
            }

            const secondGot = newBlink.getOrPut(secondNum) catch unreachable;
            if (secondGot.found_existing) {
                secondGot.value_ptr.* += value;
            } else {
                secondGot.value_ptr.* = value;
            }
        } else {
            const got = newBlink.getOrPut(key * 2024) catch unreachable;
            if (got.found_existing) {
                got.value_ptr.* += value;
            } else {
                got.value_ptr.* = value;
            }
        }
    }

    return blink(alloc, &newBlink, iterations - 1);
}

fn printStones(stones: *Stones) void {
    for (stones.items) |stone| {
        std.debug.print("{} ", .{stone});
    }

    std.debug.print("\n", .{});
}

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // const input = "125 17";

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var stonesList = Stones.init(alloc);
    defer stonesList.deinit();

    var stones = StonesMap.init(alloc);
    defer stones.deinit();

    var stoneIter = std.mem.splitScalar(u8, input, ' ');
    while (stoneIter.next()) |stone| {
        const stoneNum = std.fmt.parseUnsigned(
            u64,
            if (stone[stone.len - 1] == '\n') stone[0 .. stone.len - 1] else stone,
            10,
        ) catch unreachable;

        stones.put(stoneNum, 1) catch unreachable;
        stonesList.append(stoneNum) catch unreachable;
    }

    const count = blink(&alloc, &stones, 75);
    // for (0..7) |_| {
    //     blinkList(&stonesList);
    // }
    // printStones(&stonesList);

    std.debug.print("{}\n", .{count});
}
