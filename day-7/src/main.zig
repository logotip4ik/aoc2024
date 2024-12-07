const std = @import("std");

const print = std.debug.print;

var buff: [1000]u8 = undefined;
fn isCalculatable(
    res: u64,
    current: u64,
    numbers: []u64,
    currentOperatorIdx: u8,
) bool {
    if (numbers.len == 0) {
        return current == res;
    }

    const nextInt = numbers[0];

    const currentRes = switch (currentOperatorIdx) {
        0 => current + nextInt,
        1 => current * nextInt,
        2 => a: {
            const concatStr = std.fmt.bufPrint(&buff, "{}{}", .{ current, nextInt }) catch unreachable;

            break :a std.fmt.parseInt(u64, concatStr, 10) catch unreachable;
        },

        else => @panic("unknown operator"),
    };

    for (0..3) |i| {
        if (isCalculatable(
            res,
            currentRes,
            numbers[1..],
            @intCast(i),
        )) {
            return true;
        }
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input =
    //     \\190: 10 19
    //     \\3267: 81 40 27
    //     \\83: 17 5
    //     \\156: 15 6
    //     \\7290: 6 8 6 15
    //     \\161011: 16 10 13
    //     \\192: 17 8 14
    //     \\21037: 9 7 18 13
    //     \\292: 11 6 16 20
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var numbers = std.ArrayList(u64).init(alloc);
    defer numbers.deinit();

    var sum1: u64 = 0;

    var lineIter = std.mem.splitScalar(u8, input, '\n');
    while (lineIter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const colIdx = std.mem.indexOfScalar(u8, line, ':').?;

        const res = std.fmt.parseInt(u64, line[0..colIdx], 10) catch unreachable;

        // + 1 for column itself + 1 for space before first number
        const numbersString = line[colIdx + 1 + 1 .. line.len];
        var numberIter = std.mem.splitScalar(u8, numbersString, ' ');
        while (numberIter.next()) |numStr| {
            const num = std.fmt.parseInt(u64, numStr, 10) catch unreachable;
            numbers.append(num) catch unreachable;
        }
        defer numbers.clearRetainingCapacity();

        if (isCalculatable(
            res,
            0,
            numbers.items,
            0,
        )) {
            sum1 += res;
        }
    }

    print("2 part - {}\n", .{sum1});
}
