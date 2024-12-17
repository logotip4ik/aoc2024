const std = @import("std");

const Alloc = std.mem.Allocator;

const Move = enum {
    Up,
    Right,
    Bottom,
    Left,
};

const Spot = enum {
    Empty,
    BoxL,
    BoxR,
    Wall,
};

const Pos = struct {
    x: u16,
    y: u16,
};

const PosWithSpot = struct {
    x: u16,
    y: u16,
    value: Spot,
};

const Positions = std.ArrayList(*PosWithSpot);
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

fn includesPos(positions: *const Positions, pos: *const PosWithSpot) bool {
    for (positions.items) |item| {
        if (item.x == pos.x and item.y == pos.y) {
            return true;
        }
    }

    return false;
}

fn printMap(map: *const Map, robotPos: *const Pos) void {
    std.debug.print(" ", .{});
    for (0..map.items[0].items.len) |i| {
        if (i % 2 == 0) {
            std.debug.print("{} ", .{i});
        }
    }
    std.debug.print("\n", .{});

    for (map.items, 0..) |row, y| {
        std.debug.print("{}", .{y});

        for (row.items, 0..) |s, x| {
            if (x == robotPos.x and y == robotPos.y) {
                std.debug.print("@", .{});
            } else if (s == .Empty) {
                std.debug.print(".", .{});
            } else if (s == .BoxL) {
                std.debug.print("[", .{});
            } else if (s == .BoxR) {
                std.debug.print("]", .{});
            } else if (s == .Wall) {
                std.debug.print("#", .{});
            }
        }

        std.debug.print("\n", .{});
    }

    std.debug.print("  ", .{});
    for (0..map.items[0].items.len) |i| {
        if (i % 2 != 0) {
            std.debug.print("{} ", .{i});
        }
    }
    std.debug.print("\n", .{});
}

fn makeNewPos(pos: *const Pos, move: Move) Pos {
    return switch (move) {
        .Up => Pos{
            .x = pos.x,
            .y = pos.y - 1,
        },
        .Right => Pos{
            .x = pos.x + 1,
            .y = pos.y,
        },
        .Bottom => Pos{
            .x = pos.x,
            .y = pos.y + 1,
        },
        .Left => Pos{
            .x = pos.x - 1,
            .y = pos.y,
        },
    };
}

fn canMove(map: *const Map, pos: *const Pos, move: Move) bool {
    const p = makeNewPos(pos, move);

    const item = map.items[p.y].items[p.x];
    return item == .BoxL or item == .BoxR or item == .Empty;
}

// fn moveVerticaly(map: *Map, pos: *Pos, move: Move, toMove: *Positions) bool {
// }

fn moveRobot(alloc: *const Alloc, map: *Map, robot: *Pos, move: Move, depth: u32, toMove: *Positions) void {
    const p = makeNewPos(robot, move);

    const item: Spot = map.items[p.y].items[p.x];

    // if (move == .Up) {
    //     for (0..depth) |_| {
    //         std.debug.print("  ", .{});
    //     }
    //     std.debug.print("item - {any}\n", .{item});
    // }

    const newRobotPos = switch (move) {
        .Left, .Right => switch (item) {
            .Empty => Pos{
                .x = p.x,
                .y = p.y,
            },
            .Wall => Pos{
                .x = robot.x,
                .y = robot.y,
            },
            .BoxL, .BoxR => blk: {
                var pCopy = Pos{ .x = p.x, .y = p.y };
                moveRobot(alloc, map, &pCopy, move, depth + 1, toMove);

                if (pCopy.x != p.x or pCopy.y != p.y) {
                    map.items[p.y].items[p.x] = .Empty;
                    map.items[pCopy.y].items[pCopy.x] = item;
                    break :blk Pos{
                        .x = p.x,
                        .y = p.y,
                    };
                } else {
                    break :blk Pos{
                        .x = robot.x,
                        .y = robot.y,
                    };
                }
            },
        },

        .Up, .Bottom => switch (item) {
            .Empty => Pos{
                .x = p.x,
                .y = p.y,
            },
            .Wall => Pos{
                .x = robot.x,
                .y = robot.y,
            },
            .BoxR => blk: {
                var lBoxCopy = Pos{ .x = p.x - 1, .y = p.y };
                var pCopy = Pos{ .x = p.x, .y = p.y };

                if (!canMove(map, &pCopy, move) or !canMove(map, &lBoxCopy, move)) {
                    toMove.clearRetainingCapacity();
                    break :blk Pos{
                        .x = robot.x,
                        .y = robot.y,
                    };
                }

                moveRobot(alloc, map, &pCopy, move, depth + 1, toMove);

                if (pCopy.x != p.x or pCopy.y != p.y) {
                    if (lBoxCopy.x == robot.x) {
                        break :blk Pos{
                            .x = p.x,
                            .y = p.y,
                        };
                    }

                    moveRobot(alloc, map, &lBoxCopy, move, depth, toMove);
                    if (lBoxCopy.y == p.y) {
                        toMove.clearRetainingCapacity();
                        break :blk Pos{
                            .x = robot.x,
                            .y = robot.y,
                        };
                    }

                    {
                        const point = alloc.create(PosWithSpot) catch unreachable;
                        point.x = p.x;
                        point.y = p.y;
                        point.value = .BoxR;
                        if (!includesPos(toMove, point)) {
                            toMove.append(point) catch unreachable;
                        }
                    }

                    // map.items[p.y].items[p.x] = .Empty;
                    // map.items[pCopy.y].items[pCopy.x] = .BoxR;

                    {
                        const point = alloc.create(PosWithSpot) catch unreachable;
                        point.x = p.x - 1;
                        point.y = p.y;
                        point.value = .BoxL;
                        if (!includesPos(toMove, point)) {
                            toMove.append(point) catch unreachable;
                        }
                    }

                    // map.items[p.y].items[p.x - 1] = .Empty;
                    // map.items[lBoxCopy.y].items[lBoxCopy.x] = .BoxL;

                    break :blk Pos{
                        .x = p.x,
                        .y = p.y,
                    };
                }

                toMove.clearRetainingCapacity();

                break :blk Pos{
                    .x = robot.x,
                    .y = robot.y,
                };
            },
            .BoxL => blk: {
                var rBoxCopy = Pos{ .x = p.x + 1, .y = p.y };
                var pCopy = Pos{ .x = p.x, .y = p.y };

                if (!canMove(map, &pCopy, move) or !canMove(map, &rBoxCopy, move)) {
                    toMove.clearRetainingCapacity();
                    break :blk Pos{
                        .x = robot.x,
                        .y = robot.y,
                    };
                }

                moveRobot(alloc, map, &pCopy, move, depth + 1, toMove);

                if (pCopy.x != p.x or pCopy.y != p.y) {
                    if (rBoxCopy.x == robot.x) {
                        break :blk Pos{
                            .x = p.x,
                            .y = p.y,
                        };
                    }

                    moveRobot(alloc, map, &rBoxCopy, move, depth, toMove);
                    if (rBoxCopy.y == p.y) {
                        toMove.clearRetainingCapacity();
                        break :blk Pos{
                            .x = robot.x,
                            .y = robot.y,
                        };
                    }

                    {
                        const point = alloc.create(PosWithSpot) catch unreachable;
                        point.x = p.x;
                        point.y = p.y;
                        point.value = .BoxL;
                        if (!includesPos(toMove, point)) {
                            toMove.append(point) catch unreachable;
                        }
                    }

                    // map.items[p.y].items[p.x] = .Empty;
                    // map.items[pCopy.y].items[pCopy.x] = .BoxL;

                    {
                        const point = alloc.create(PosWithSpot) catch unreachable;
                        point.x = p.x + 1;
                        point.y = p.y;
                        point.value = .BoxR;
                        if (!includesPos(toMove, point)) {
                            toMove.append(point) catch unreachable;
                        }
                    }

                    // map.items[p.y].items[p.x + 1] = .Empty;
                    // map.items[rBoxCopy.y].items[rBoxCopy.x] = .BoxR;

                    break :blk Pos{
                        .x = p.x,
                        .y = p.y,
                    };
                }

                toMove.clearRetainingCapacity();

                break :blk Pos{
                    .x = robot.x,
                    .y = robot.y,
                };
            },
        },
    };

    if (depth == 0 and (move == .Up or move == .Bottom)) {
        for (toMove.items) |moveItem| {
            const nextY = if (move == .Bottom) moveItem.y + 1 else moveItem.y - 1;
            // std.debug.print("{},{} -> {},{}\n", .{ moveItem.x, moveItem.y, moveItem.x, nextY });
            map.items[moveItem.y].items[moveItem.x] = .Empty;
            map.items[nextY].items[moveItem.x] = moveItem.value;
        }

        toMove.clearRetainingCapacity();
    }

    // if (move == .Up) {
    //     for (0..depth) |_| {
    //         std.debug.print("  ", .{});
    //     }
    //     std.debug.print("newRobotPos - {any}\n", .{newRobotPos});
    // }

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

    // const input =
    //     \\#######
    //     \\#...#.#
    //     \\#.....#
    //     \\#..OO@#
    //     \\#..O..#
    //     \\#.....#
    //     \\#######
    //     \\
    //     \\<vv<<^^<<^^
    // ;

    // const input =
    //     \\#######
    //     \\#...#.#
    //     \\#.....#
    //     \\#.OOO.#
    //     \\#..OO@#
    //     \\#..O..#
    //     \\#.....#
    //     \\#.....#
    //     \\#######
    //     \\
    //     \\<vv<<^^^
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
                movesBuf[insertedMoves] = switch (c) {
                    '^' => .Up,
                    '>' => .Right,
                    'v' => .Bottom,
                    '<' => .Left,
                    else => @panic("unknown move"),
                };
                insertedMoves += 1;
            }
        } else {
            var row: Row = Row.init(alloc);

            for (line) |c| {
                switch (c) {
                    '#' => {
                        row.append(.Wall) catch unreachable;
                        row.append(.Wall) catch unreachable;
                    },
                    '.', '@' => {
                        if (c == '@') {
                            robotPos.x = @intCast(row.items.len);
                            robotPos.y = @intCast(map.items.len);
                        }

                        row.append(.Empty) catch unreachable;
                        row.append(.Empty) catch unreachable;
                    },
                    'O' => {
                        row.append(.BoxL) catch unreachable;
                        row.append(.BoxR) catch unreachable;
                    },
                    '[' => row.append(.BoxL) catch unreachable,
                    ']' => row.append(.BoxR) catch unreachable,
                    else => @panic("unknown map value"),
                }
            }

            map.append(row) catch unreachable;
        }
    }

    printMap(&map, &robotPos);

    var toMove = Positions.init(alloc);
    defer {
        for (toMove.items) |item| {
            alloc.destroy(item);
        }
        toMove.deinit();
    }

    const moves = movesBuf[0..insertedMoves];
    for (moves) |move| {
        // std.debug.print("\n{any}\n", .{move});
        moveRobot(&alloc, &map, &robotPos, move, 0, &toMove);
        // printMap(&map, &robotPos);
    }

    // std.debug.print("\n", .{});
    // printMap(&map, &robotPos);

    var sum: u64 = 0;
    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |item, x| {
            if (item != .BoxL) {
                continue;
            }

            sum += 100 * y + x;
        }
    }

    std.debug.print("sum - {}\n", .{sum});
}
