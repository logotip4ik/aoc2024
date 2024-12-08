const std = @import("std");

const print = std.debug.print;

const Point = struct {
    x: u16,
    y: u16,
};

fn appendIfNotSeen(list: *std.ArrayList(*Point), point: *Point) void {
    for (list.items) |item| {
        if (item.x == point.x and item.y == point.y) {
            return;
        }
    }

    list.append(point) catch unreachable;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // const input =
    //     \\............
    //     \\........0...
    //     \\.....0......
    //     \\.......0....
    //     \\....0.......
    //     \\......A.....
    //     \\............
    //     \\............
    //     \\........A...
    //     \\.........A..
    //     \\............
    //     \\............
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var bounds: Point = .{
        .x = 0,
        .y = 0,
    };

    var pointsMap = std.AutoHashMap(u8, []*Point).init(alloc);

    var lineIter = std.mem.splitScalar(u8, input, '\n');
    var lineY: u16 = 0;
    while (lineIter.next()) |line| : (lineY += 1) {
        if (line.len == 0) {
            continue;
        }

        bounds.x = @intCast(line.len);
        bounds.y = lineY + 1;

        for (line, 0..) |freq, x| {
            if (freq == '.') {
                continue;
            }

            const newPoint = alloc.create(Point) catch unreachable;
            newPoint.*.x = @intCast(x);
            newPoint.*.y = lineY;

            const pointsGot = pointsMap.getOrPut(freq) catch unreachable;
            if (pointsGot.found_existing) {
                const newPointsArrayLen = pointsGot.value_ptr.len + 1;
                const newPointsArray = alloc.realloc(pointsGot.value_ptr.*, newPointsArrayLen) catch unreachable;

                newPointsArray[newPointsArrayLen - 1] = newPoint;

                pointsGot.value_ptr.* = newPointsArray;
            } else {
                const pointsArray = alloc.alloc(*Point, 1) catch unreachable;
                pointsArray[0] = newPoint;

                pointsGot.value_ptr.* = pointsArray;
            }
        }
    }

    var pointsArr = std.ArrayList(*Point).init(alloc);

    var pointsIter = pointsMap.valueIterator();
    while (pointsIter.next()) |pointsPtr| {
        const points = pointsPtr.*;

        for (points) |alignPoint| {
            for (points) |point| {
                if (alignPoint == point) {
                    continue;
                }

                appendIfNotSeen(&pointsArr, alignPoint);
                appendIfNotSeen(&pointsArr, point);

                const xOffset = @as(i32, @intCast(point.x)) - @as(i32, @intCast(alignPoint.x));
                const yOffset = @as(i32, @intCast(point.y)) - @as(i32, @intCast(alignPoint.y));

                var prevPoint = point;

                while (true) {
                    const anitpointX = @as(i32, @intCast(prevPoint.x)) + xOffset;
                    const anitpointY = @as(i32, @intCast(prevPoint.y)) + yOffset;

                    if (anitpointX < 0 or anitpointY < 0) {
                        break;
                    }

                    if (anitpointX > bounds.x - 1 or anitpointY > bounds.y - 1) {
                        break;
                    }

                    const antipoint = alloc.create(Point) catch unreachable;
                    antipoint.*.x = @intCast(anitpointX);
                    antipoint.*.y = @intCast(anitpointY);

                    appendIfNotSeen(&pointsArr, antipoint);

                    prevPoint = antipoint;
                }
            }
        }
    }

    print("2 part - {}\n", .{pointsArr.items.len});
}
