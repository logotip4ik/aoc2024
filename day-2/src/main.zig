const std = @import("std");

const sub = std.math.sub;

fn getDir(n1: u16, n2: u16) enum { Asc, Dsc } {
    const substraction = sub(i16, @intCast(n1), @intCast(n2)) catch unreachable;

    return if (substraction < 0) .Asc else .Dsc;
}

fn parseInt(str: []const u8) u16 {
    return std.fmt.parseInt(u16, str, 10) catch unreachable;
}

fn isSafeReport(list: []u16) bool {
    const dir = getDir(list[0], list[1]);
    var prevNum = list[0];

    for (list[1..]) |num| {
        const dist = sub(i16, @intCast(prevNum), @intCast(num)) catch unreachable;
        const currentDir = getDir(prevNum, num);

        prevNum = num;

        if (dir != currentDir) {
            return false;
        }

        if (@abs(dist) < 1 or @abs(dist) > 3) {
            return false;
        }
    }

    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var safeReports: u16 = 0;
    var buf: [128]u8 = undefined;

    // PART 1
    // outer: while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    //     var numIter = std.mem.split(u8, line, &[_]u8{' '});
    //
    //     const numOne = parseInt(numIter.next().?);
    //     var prevNum = parseInt(numIter.next().?);
    //     const firstDist = sub(i16, @intCast(numOne), @intCast(prevNum)) catch unreachable;
    //
    //     if (@abs(firstDist) < 1 or @abs(firstDist) > 3) {
    //         continue;
    //     }
    //
    //     const dir = getDir(numOne, prevNum);
    //
    //     while (numIter.next()) |numString| {
    //         const num = parseInt(numString);
    //         const dist = sub(i16, @intCast(prevNum), @intCast(num)) catch unreachable;
    //
    //         if (dir != getDir(prevNum, num)) {
    //             prevNum = num;
    //             continue :outer;
    //         }
    //
    //         prevNum = num;
    //
    //         if (@abs(dist) < 1 or @abs(dist) > 3) {
    //             continue :outer;
    //         }
    //     }
    //
    //     safeReports += 1;
    // }

    // PART 2
    var report = std.ArrayList(u16).init(alloc);
    defer report.deinit();

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        report.clearRetainingCapacity();

        var numIter = std.mem.split(u8, line, &[_]u8{' '});

        while (numIter.next()) |numString| {
            const num = parseInt(numString);

            try report.append(num);
        }

        if (isSafeReport(report.items)) {
            safeReports += 1;
        } else {
            for (0..report.items.len) |toSkip| {
                var reportWithSkippedElement = try report.clone();
                defer reportWithSkippedElement.deinit();

                _ = reportWithSkippedElement.orderedRemove(toSkip);

                if (isSafeReport(reportWithSkippedElement.items)) {
                    safeReports += 1;
                    break;
                }
            }
        }
    }

    std.debug.print("{}\n", .{safeReports});
}
