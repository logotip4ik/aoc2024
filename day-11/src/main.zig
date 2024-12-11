const std = @import("std");

const Stones = std.ArrayList(u64);

var buf: [1000]u8 = undefined;
fn blink(stones: *Stones) void {
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

fn printStones(stones: *Stones) void {
    for (stones.items) |stone| {
        std.debug.print("{d} ", .{stone});
    }

    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input = "125 17";

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var stones = Stones.init(alloc);
    defer stones.deinit();

    var stoneIter = std.mem.splitScalar(u8, input, ' ');
    while (stoneIter.next()) |stone| {
        const stoneNum = std.fmt.parseUnsigned(
            u64,
            if (stone[stone.len - 1] == '\n') stone[0 .. stone.len - 1] else stone,
            10,
        ) catch unreachable;

        stones.append(stoneNum) catch unreachable;
    }

    printStones(&stones);

    for (0..25) |_| {
        blink(&stones);
        // printStones(&stones);
    }

    std.debug.print("{}\n", .{stones.items.len});
}
