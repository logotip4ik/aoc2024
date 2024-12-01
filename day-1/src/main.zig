const std = @import("std");

const Allocator = std.mem.Allocator;
const fs = std.fs;
const print = std.debug.print;
const mem = std.mem;

const MAX32INT = std.math.maxInt(u32);

const SmallestIter = struct {
    const Self = @This();

    list: *[]u32,
    lastSmallestIdx: u32,

    pub fn init(items: *[]u32) Self {
        return .{
            .list = items,
            .lastSmallestIdx = 0,
        };
    }

    pub fn next(self: *Self) ?u32 {
        const list = self.list.*;
        const smallestIdx = mem.indexOfMin(u32, list);

        if (list[smallestIdx] == MAX32INT) {
            return null;
        }

        const num = list[smallestIdx];
        list[smallestIdx] = MAX32INT;

        return @intCast(num);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var listOne = std.ArrayList(u32).init(alloc);
    defer listOne.deinit();

    var listTwo = std.ArrayList(u32).init(alloc);
    defer listTwo.deinit();

    var buf: [24]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var numbersIter = std.mem.split(u8, line, "   ");

        const numInFirstList = numbersIter.next().?;
        const numInSecondList = numbersIter.next().?;

        try listOne.append(
            try std.fmt.parseInt(u32, numInFirstList, 10),
        );

        try listTwo.append(
            try std.fmt.parseInt(u32, numInSecondList, 10),
        );
    }

    // PART 1
    // var listOneIter = SmallestIter.init(&listOne.items);
    // var listTwoIter = SmallestIter.init(&listTwo.items);
    // var sum: u32 = 0;
    //
    // for (0..listOne.items.len) |_| {
    //     const smallestInFirstList = listOneIter.next().?;
    //     const smallestInSecondList = listTwoIter.next().?;
    //
    //     const dist = if (smallestInFirstList < smallestInSecondList) smallestInSecondList - smallestInFirstList else smallestInFirstList - smallestInSecondList;
    //
    //     sum += dist;
    // }
    //
    // print("{}\n", .{sum});

    var sum: u64 = 0;
    for (listOne.items) |item| {
        const viewed = mem.count(u32, listTwo.items, &[1]u32{item});

        const simularity: u64 = viewed * item;

        sum += simularity;
    }

    print("{}\n", .{sum});
}
