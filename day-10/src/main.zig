const std = @import("std");

const Alloc = std.mem.Allocator;
const print = std.debug.print;

const Pos = struct {
    x: u32,
    y: u32,
};

const Start = struct {
    x: u32,
    y: u32,
    score: u32,
};

const Path = std.ArrayList(*Pos);
const Line = std.ArrayList(u8);
const Map = std.ArrayList(Line);

fn printMap(map: *Map) void {
    for (map.items) |line| {
        for (line.items) |p| {
            if (p == '.') {
                print(". ", .{});
            } else {
                print("{d} ", .{p});
            }
        }

        print("\n", .{});
    }
}

fn beenAt(path: *Path, p: *Pos) bool {
    for (path.items) |pos| {
        if (pos.x == p.x and pos.y == p.y) {
            return true;
        }
    }

    return false;
}

fn isSuitableNewPos(map: *Map, path: *Path, currentPos: *Pos, newPos: *Pos) bool {
    if (beenAt(path, newPos)) {
        return false;
    }

    const currentHeight = map.items[currentPos.y].items[currentPos.x];
    const newHeight = map.items[newPos.y].items[newPos.x];

    return newHeight > currentHeight and newHeight - currentHeight == 1;
}

fn walk(alloc: Alloc, map: *Map, path: *Path, start: *Start, seenTails: *Path) void {
    const currentPos = path.getLast();

    const currentHeight = map.items[currentPos.y].items[currentPos.x];

    if (currentHeight == 9) {
        // if (!beenAt(seenTails, currentPos)) {
        start.*.score += 1;

        const tail = alloc.create(Pos) catch unreachable;
        tail.*.x = currentPos.x;
        tail.*.y = currentPos.y;

        seenTails.append(tail) catch unreachable;
        // }

        return;
    }

    const newPos = alloc.create(Pos) catch unreachable;

    if (currentPos.y > 0) {
        newPos.*.x = currentPos.x;
        newPos.*.y = currentPos.y - 1;

        // print("Up? ", .{});

        if (isSuitableNewPos(map, path, currentPos, newPos)) {
            path.append(newPos) catch unreachable;

            // print("Up\n", .{});

            walk(alloc, map, path, start, seenTails);

            _ = path.pop();
        }
    }

    if (currentPos.x + 1 < map.items[0].items.len) {
        newPos.*.x = currentPos.x + 1;
        newPos.*.y = currentPos.y;

        // print("Right? ", .{});

        if (isSuitableNewPos(map, path, currentPos, newPos)) {
            path.append(newPos) catch unreachable;

            // print("Right\n", .{});
            walk(alloc, map, path, start, seenTails);

            _ = path.pop();
        }
    }

    if (currentPos.y + 1 < map.items.len) {
        newPos.*.x = currentPos.x;
        newPos.*.y = currentPos.y + 1;

        // print("Bottom? ", .{});

        if (isSuitableNewPos(map, path, currentPos, newPos)) {
            path.append(newPos) catch unreachable;

            // print("Down\n", .{});

            walk(alloc, map, path, start, seenTails);

            _ = path.pop();
        }
    }

    if (currentPos.x > 0) {
        newPos.*.x = currentPos.x - 1;
        newPos.*.y = currentPos.y;

        // print("Left? ", .{});

        if (isSuitableNewPos(map, path, currentPos, newPos)) {
            path.append(newPos) catch unreachable;

            // print("Left\n", .{});

            walk(alloc, map, path, start, seenTails);

            _ = path.pop();
        }
    }

    alloc.destroy(newPos);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // const input =
    //     \\89010123
    //     \\78121874
    //     \\87430965
    //     \\96549874
    //     \\45678903
    //     \\32019012
    //     \\01329801
    //     \\10456732
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var map = Map.init(alloc);
    var starts = std.ArrayList(*Start).init(alloc);

    var y: u32 = 0;
    var lineIter = std.mem.splitScalar(u8, input, '\n');
    while (lineIter.next()) |line| : (y += 1) {
        if (line.len == 0) {
            continue;
        }

        var lineArr = Line.initCapacity(alloc, line.len) catch unreachable;

        for (line, 0..) |c, x| {
            if (std.ascii.isDigit(c)) {
                const d = c - 48;

                lineArr.appendAssumeCapacity(d);

                if (d == 0) {
                    const start = alloc.create(Start) catch unreachable;

                    start.*.x = @intCast(x);
                    start.*.y = @intCast(y);
                    start.*.score = 0;

                    starts.append(start) catch unreachable;
                }
            } else {
                lineArr.appendAssumeCapacity('.');
            }
        }

        map.append(lineArr) catch unreachable;
    }

    var path = Path.init(alloc);
    var sum: u32 = 0;

    var tails = Path.init(alloc);

    for (starts.items, 0..) |start, i| {
        const startPos = alloc.create(Pos) catch unreachable;
        startPos.*.x = start.x;
        startPos.*.y = start.y;

        path.append(startPos) catch unreachable;

        walk(alloc, &map, &path, starts.items[i], &tails);

        for (path.items) |pos| {
            alloc.destroy(pos);
        }
        path.clearRetainingCapacity();

        for (tails.items) |tail| {
            alloc.destroy(tail);
        }
        tails.clearRetainingCapacity();

        alloc.destroy(startPos);

        sum += start.score;
    }

    print("{}\n", .{sum});
}
