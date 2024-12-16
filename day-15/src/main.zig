const std = @import("std");

const Move = enum {
    Up,
    Right,
    Bottom,
    Left,
};

const Spot = enum {
    Empty,
    Box,
    Wall,
};

const Pos = struct {
    x: u16,
    y: u16,
};

const Row = std.ArrayList(Spot);
const Map = std.ArrayList(Row);

fn printMoves(moves: *const []Move) void {
    for (moves.*) |move| {
        switch (move) {
            .Up => std.debug.print("^", .{}),
            .Right => std.debug.print(">", .{}),
            .Bottom => std.debug.print("v", .{}),
            .Left => std.debug.print("<", .{}),
        }
    }
    std.debug.print("\n", .{});
}

fn printMap(map: *const Map, robotPos: *const Pos) void {
    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |s, x| {
            if (x == robotPos.x and y == robotPos.y) {
                std.debug.print("@", .{});
            } else if (s == .Empty) {
                std.debug.print(".", .{});
            } else if (s == .Box) {
                std.debug.print("O", .{});
            } else if (s == .Wall) {
                std.debug.print("#", .{});
            }
        }

        std.debug.print("\n", .{});
    }
}

fn moveRobot(map: *Map, robot: *Pos, move: Move) void {
    const p = switch (move) {
        .Up => Pos{
            .x = robot.x,
            .y = robot.y - 1,
        },
        .Right => Pos{
            .x = robot.x + 1,
            .y = robot.y,
        },
        .Bottom => Pos{
            .x = robot.x,
            .y = robot.y + 1,
        },
        .Left => Pos{
            .x = robot.x - 1,
            .y = robot.y,
        },
    };

    const item = map.items[p.y].items[p.x];
    // std.debug.print("item - {any}\n", .{item});
    const newRobotPos = switch (item) {
        .Empty => Pos{
            .x = p.x,
            .y = p.y,
            // newRobotPos.x = p.x;
            // newRobotPos.y = p.y;
        },
        .Box => blk: {
            var pCopy = Pos{ .x = p.x, .y = p.y };

            // const tempSpot = map.items[p.y].items[p.x];
            moveRobot(map, &pCopy, move);
            map.items[p.y].items[p.x] = .Empty;
            map.items[pCopy.y].items[pCopy.x] = .Box;

            if (map.items[p.y].items[p.x] == .Empty) {
                break :blk Pos{
                    .x = p.x,
                    .y = p.y,
                };
            }

            break :blk Pos{
                .x = robot.x,
                .y = robot.y,
            };
        },
        .Wall => Pos{
            .x = robot.x,
            .y = robot.y,
            // newRobotPos.x = robot.x;
            // newRobotPos.y = robot.y;
        },
    };

    // std.debug.print("newRobotPos - {any}\n", .{newRobotPos});
    robot.x = newRobotPos.x;
    robot.y = newRobotPos.y;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // const input =
    //     \\##########
    //     \\#..O..O.O#
    //     \\#......O.#
    //     \\#.OO..O.O#
    //     \\#..O@..O.#
    //     \\#O#..O...#
    //     \\#O..O..O.#
    //     \\#.OO.O.OO#
    //     \\#....O...#
    //     \\##########
    //     \\
    //     \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    //     \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    //     \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    //     \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    //     \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    //     \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    //     \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    //     \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    //     \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    //     \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var movesBuf: [99999]Move = undefined;
    var insertedMoves: u16 = 0;

    var map = Map.init(alloc);
    defer map.deinit();

    var robotPos: Pos = .{ .x = 0, .y = 0 };

    var madeMap = false;
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    while (linesIter.next()) |line| {
        if (line.len == 0) {
            madeMap = true;
            continue;
        }

        if (madeMap) {
            for (line) |c| {
                switch (c) {
                    '^' => {
                        movesBuf[insertedMoves] = .Up;
                    },
                    '>' => {
                        movesBuf[insertedMoves] = .Right;
                    },
                    'v' => {
                        movesBuf[insertedMoves] = .Bottom;
                    },
                    '<' => {
                        movesBuf[insertedMoves] = .Left;
                    },
                    else => @panic("unknown move"),
                }
                insertedMoves += 1;
            }
        } else {
            var row: Row = Row.init(alloc);

            for (line) |c| {
                switch (c) {
                    '#' => {
                        row.append(.Wall) catch unreachable;
                    },
                    '.', '@' => {
                        if (c == '@') {
                            robotPos.x = @intCast(row.items.len);
                            robotPos.y = @intCast(map.items.len);
                        }

                        row.append(.Empty) catch unreachable;
                    },
                    'O' => {
                        row.append(.Box) catch unreachable;
                    },
                    else => @panic("unknown map value"),
                }
            }

            map.append(row) catch unreachable;
        }
    }

    // std.debug.print("{}\n", .{map.items.len});

    printMap(&map, &robotPos);

    const moves = movesBuf[0..insertedMoves];
    for (moves) |move| {
        moveRobot(&map, &robotPos, move);
    }

    std.debug.print("\n", .{});
    printMap(&map, &robotPos);

    var sum: u64 = 0;
    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |item, x| {
            if (item != .Box) {
                continue;
            }

            sum += 100 * y + x;
        }
    }

    std.debug.print("sum - {}\n", .{sum});
}
