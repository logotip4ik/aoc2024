const std = @import("std");
const Alloc = std.mem.Allocator;

const Point = enum {
    Plain,
    Obstacle,
};

const Dir = enum {
    Up,
    Right,
    Bottom,
    Left,
};

const Guard = struct {
    x: u16,
    y: u16,
    dir: Dir,
};

const Line = std.ArrayList(Point);
const City = std.ArrayList(Line);
const Viewed = std.StringHashMap(bool);

fn getNextDir(dir: Dir) Dir {
    return switch (dir) {
        .Up => .Right,
        .Right => .Bottom,
        .Bottom => .Left,
        .Left => .Up,
    };
}

fn getGuardPosKey(alloc: Alloc, guard: *Guard) []const u8 {
    return std.fmt.allocPrint(alloc, "{},{}", .{ guard.x, guard.y }) catch unreachable;
}

fn walk(alloc: Alloc, city: *City, guard: *Guard, viewed: *Viewed) void {
    const oldGuard = guard.*;

    const posKey = getGuardPosKey(alloc, guard);
    const gop = viewed.getOrPut(posKey) catch unreachable;
    if (gop.found_existing) {
        alloc.free(posKey);
    }

    switch (guard.dir) {
        .Up => {
            if (@as(i16, @intCast(guard.y)) - 1 < 0) {
                return;
            }

            guard.*.y -= 1;
        },

        .Right => {
            if (guard.x + 1 > city.items[guard.y].items.len - 1) {
                return;
            }

            guard.*.x += 1;
        },

        .Bottom => {
            if (guard.y + 1 > city.items.len - 1) {
                return;
            }

            guard.*.y += 1;
        },

        .Left => {
            if (@as(i16, @intCast(guard.x)) - 1 < 0) {
                return;
            }

            guard.*.x -= 1;
        },
    }

    if (city.items[guard.y].items[guard.x] == .Obstacle) {
        guard.*.dir = getNextDir(guard.dir);
        guard.*.x = oldGuard.x;
        guard.*.y = oldGuard.y;
    }

    walk(alloc, city, guard, viewed);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input =
    //     \\....#.....
    //     \\.........#
    //     \\..........
    //     \\..#.......
    //     \\.......#..
    //     \\..........
    //     \\.#..^.....
    //     \\........#.
    //     \\#.........
    //     \\......#...
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var city = City.init(alloc);
    defer {
        for (city.items) |line| {
            line.deinit();
        }

        city.deinit();
    }

    var guard: Guard = undefined;
    var y: u16 = 0;

    var linesIter = std.mem.splitScalar(u8, input, '\n');

    while (linesIter.next()) |line| : (y += 1) {
        if (line.len == 0) {
            continue;
        }

        var lineArr = try Line.initCapacity(alloc, line.len);

        for (line, 0..) |point, x| {
            switch (point) {
                '.' => lineArr.appendAssumeCapacity(.Plain),
                '#' => lineArr.appendAssumeCapacity(.Obstacle),
                '^' => {
                    lineArr.appendAssumeCapacity(.Plain);
                    guard = .{ .x = @intCast(x), .y = y, .dir = .Up };
                },
                else => @panic("unknown symbol"),
            }
        }

        try city.append(lineArr);
    }

    var viewed = Viewed.init(alloc);
    defer {
        var keyIter = viewed.keyIterator();
        while (keyIter.next()) |keyPtr| {
            alloc.free(keyPtr.*);
        }

        viewed.deinit();
    }

    walk(alloc, &city, &guard, &viewed);

    std.debug.print("{}\n", .{viewed.count()});
}
