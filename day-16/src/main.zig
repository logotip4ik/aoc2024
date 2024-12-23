const std = @import("std");

const Alloc = std.mem.Allocator;

const Point = enum { Wall, Empty, End };
const Dir = enum { Up, Right, Bottom, Left };

const Pos = struct {
    x: u32,
    y: u32,
};

const Location = struct {
    const Self = @This();

    x: u32,
    y: u32,
    cost: u64,
    dir: Dir,
    parent: ?*const Location,

    pub fn new(
        alloc: Alloc,
        x: u32,
        y: u32,
        cost: u64,
        dir: Dir,
        parent: ?*const Location,
    ) !*Self {
        const location = try alloc.create(Self);

        location.x = x;
        location.y = y;
        location.cost = cost;
        location.dir = dir;
        location.parent = parent;

        return location;
    }
};

const Row = std.ArrayList(Point);
const Map = std.ArrayList(Row);

fn generateLocationKey(x: u32, y: u32, dir: Dir) u64 {
    return @as(u64, x) | (@as(u64, y) << 32) | (@as(u64, @intFromEnum(dir)) << 62);
}

fn tracePath(map: *const Map, end: *const Location) void {
    var node = end;
    std.debug.print("({},{}) - {}\n", .{ node.x, node.y, node.dir });

    while (node.parent) |parent| {
        const dirString = switch (parent.dir) {
            .Up => "Up",
            .Right => "Right",
            .Bottom => "Bottom",
            .Left => "Left",
        };

        std.debug.print("({:2},{:2}) - {s:6}\n", .{ parent.x, parent.y, dirString });
        node = parent;
    }

    _ = map;
}

fn pCompareLocations(_: void, a: *const Location, b: *const Location) std.math.Order {
    if (a.cost == b.cost) {
        return .eq;
    }

    return if (a.cost < b.cost) .lt else .gt;
}

fn printMapWithLocation(map: *const Map, l: *const Location) void {
    const stdout = std.io.getStdOut();

    var buf = std.io.bufferedWriter(stdout.writer());
    const writer = buf.writer();

    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |spot, x| {
            if (x == l.x and y == l.y) {
                switch (l.dir) {
                    .Up => writer.print("^", .{}) catch unreachable,
                    .Right => writer.print(">", .{}) catch unreachable,
                    .Bottom => writer.print("v", .{}) catch unreachable,
                    .Left => writer.print("<", .{}) catch unreachable,
                }
            } else {
                switch (spot) {
                    .Wall => writer.print("#", .{}) catch unreachable,
                    .Empty => writer.print(".", .{}) catch unreachable,
                    .End => writer.print("E", .{}) catch unreachable,
                }
            }
        }

        writer.print("\n", .{}) catch unreachable;
    }

    buf.flush() catch unreachable;
}

fn printMap(map: *const Map) void {
    for (map.items) |row| {
        for (row.items) |spot| {
            switch (spot) {
                .Wall => std.debug.print("#", .{}),
                .Empty => std.debug.print(".", .{}),
                .End => std.debug.print("E", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // const input =
    //     \\###############
    //     \\#.......#....E#
    //     \\#.#.###.#.###.#
    //     \\#.....#.#...#.#
    //     \\#.###.#####.#.#
    //     \\#.#.#.......#.#
    //     \\#.#.#####.###.#
    //     \\#...........#.#
    //     \\###.#.#####.#.#
    //     \\#...#.....#.#.#
    //     \\#.#.#.###.#.#.#
    //     \\#.....#...#.#.#
    //     \\#.###.#.#.#.#.#
    //     \\#S..#.....#...#
    //     \\###############
    // ;

    // const input =
    //     \\###############
    //     \\#..#....#....E#
    //     \\#.......#.#...#
    //     \\#.###.#.#.#...#
    //     \\#S..#.....#...#
    //     \\###############
    // ;

    // const input =
    //     \\#####
    //     \\###E#
    //     \\#...#
    //     \\#S.##
    //     \\#####
    // ;

    // const input =
    //     \\##########
    //     \\#.......E#
    //     \\#.##.#####
    //     \\#..#.....#
    //     \\##.#####.#
    //     \\#S.......#
    //     \\##########
    // ;

    // const input =
    //     \\#################
    //     \\#...#...#...#..E#
    //     \\#.#.#.#.#.#.#.#.#
    //     \\#.#.#.#...#...#.#
    //     \\#.#.#.#.###.#.#.#
    //     \\#...#.#.#.....#.#
    //     \\#.#.#.#.#.#####.#
    //     \\#.#...#.#.#.....#
    //     \\#.#.#####.#.###.#
    //     \\#.#.#.......#...#
    //     \\#.#.###.#####.###
    //     \\#.#.#...#.....#.#
    //     \\#.#.#.#####.###.#
    //     \\#.#.#.........#.#
    //     \\#.#.#.#########.#
    //     \\#S#.............#
    //     \\#################
    // ;

    // const input =
    //     \\#########
    //     \\#....#.E#
    //     \\#S.#....#
    //     \\#########
    // ;

    // const input =
    //     \\#################################
    //     \\#...................#..........E#
    //     \\#...................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.................#...........#
    //     \\#.#.............................#
    //     \\#S#.............................#
    //     \\#################################
    // ;

    // const input =
    //     \\###########################
    //     \\#######################..E#
    //     \\######################..#.#
    //     \\#####################..##.#
    //     \\####################..###.#
    //     \\###################..##...#
    //     \\##################..###.###
    //     \\#################..####...#
    //     \\################..#######.#
    //     \\###############..##.......#
    //     \\##############..###.#######
    //     \\#############..####.......#
    //     \\############..###########.#
    //     \\###########..##...........#
    //     \\##########..###.###########
    //     \\#########..####...........#
    //     \\########..###############.#
    //     \\#######..##...............#
    //     \\######..###.###############
    //     \\#####..####...............#
    //     \\####..###################.#
    //     \\###..##...................#
    //     \\##..###.###################
    //     \\#..####...................#
    //     \\#.#######################.#
    //     \\#S........................#
    //     \\###########################
    // ;

    // const input =
    //     \\##########################################################################################################
    //     \\#.........#.........#.........#.........#.........#.........#.........#.........#.........#.........#...E#
    //     \\#.........#.........#.........#.........#.........#.........#.........#.........#.........#.........#....#
    //     \\#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#
    //     \\#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#
    //     \\#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#
    //     \\#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#....#
    //     \\#....#.........#.........#.........#.........#.........#.........#.........#.........#.........#.........#
    //     \\#S...#.........#.........#.........#.........#.........#.........#.........#.........#.........#.........#
    //     \\##########################################################################################################
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var start = Pos{ .x = 0, .y = 0 };
    var end = Pos{ .x = 0, .y = 0 };

    var map = Map.init(alloc);

    var emptySpots: u32 = 0;
    var lineY: u32 = 0;
    var lineIter = std.mem.splitScalar(u8, input, '\n');
    while (lineIter.next()) |line| : (lineY += 1) {
        if (line.len == 0) {
            continue;
        }

        var row = Row.initCapacity(alloc, line.len) catch unreachable;
        for (line, 0..) |c, x| {
            if (c == '.') {
                emptySpots += 1;
            }

            const point: Point = switch (c) {
                '#' => .Wall,
                '.' => .Empty,
                'E' => blk: {
                    end.x = @intCast(x);
                    end.y = @intCast(lineY);
                    break :blk .End;
                },
                'S' => blk: {
                    start.x = @intCast(x);
                    start.y = @intCast(lineY);
                    break :blk .Empty;
                },
                else => @panic("unknown map value"),
            };

            row.appendAssumeCapacity(point);
        }

        map.append(row) catch unreachable;
    }

    var visited = std.AutoHashMap(u64, u64).init(alloc);
    defer visited.deinit();

    var q = std.PriorityQueue(*const Location, void, pCompareLocations).init(alloc, {});
    defer q.deinit();

    const startLoc = Location.new(alloc, start.x, start.y, 0, .Right, null) catch unreachable;
    q.add(startLoc) catch unreachable;

    const maxX = map.items[0].items.len;
    const maxY = map.items.len;

    while (q.items.len > 0) {
        const location = q.remove();

        // turns out if you start generating string for each location in arena you could run out of
        // memory and this will kill your program without any error message... Very interesting...
        // took me like what? 6 days without and 1 day with Gemini + giving it my input
        // maze. ohmygod
        const locationKey = generateLocationKey(location.x, location.y, location.dir);
        const locationGot = visited.getOrPut(locationKey) catch unreachable;
        if (locationGot.found_existing and locationGot.value_ptr.* < location.cost) {
            continue;
        }

        locationGot.value_ptr.* = location.cost;

        if (location.x == end.x and location.y == end.y) {
            tracePath(&map, location);
            std.debug.print("{d}\n", .{location.cost});
            break;
        }

        const rotations: [2]Dir = switch (location.dir) {
            .Up => [2]Dir{ .Left, .Right },
            .Right => [2]Dir{ .Up, .Bottom },
            .Bottom => [2]Dir{ .Right, .Left },
            .Left => [2]Dir{ .Bottom, .Up },
        };

        for (rotations) |rotation| {
            const toCheck = Location.new(
                alloc,
                location.x,
                location.y,
                location.cost + 1000,
                rotation,
                location,
            ) catch unreachable;

            q.add(toCheck) catch unreachable;
        }

        const offset: struct { i8, i8 } = switch (location.dir) {
            .Up => .{ 0, -1 },
            .Right => .{ 1, 0 },
            .Bottom => .{ 0, 1 },
            .Left => .{ -1, 0 },
        };
        const nx = @as(i32, @intCast(location.x)) + offset[0];
        const ny = @as(i32, @intCast(location.y)) + offset[1];

        if (nx > 0 and ny > 0) {
            const newX: u32 = @intCast(nx);
            const newY: u32 = @intCast(ny);

            if (newX < maxX and newY < maxY and map.items[newY].items[newX] != .Wall) {
                const toCheck = Location.new(
                    alloc,
                    newX,
                    newY,
                    location.cost + 1,
                    location.dir,
                    location,
                ) catch unreachable;

                q.add(toCheck) catch unreachable;
            }
        }
    }
}
