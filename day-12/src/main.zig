const std = @import("std");

const Alloc = std.mem.Allocator;

const Row = std.ArrayList(u8);
const Map = std.ArrayList(Row);

const Pos = struct {
    x: u16,
    y: u16,
};

const Region = std.ArrayList(*Pos);
const RegionsList = std.ArrayList(Region);

fn includedInRegion(list: *const Region, pos: *const Pos) bool {
    for (list.items) |r| {
        if (r.x == pos.x and r.y == pos.y) {
            return true;
        }
    }

    return false;
}

fn walk(alloc: *const Alloc, map: *const Map, region: *Region) void {
    const currentPos = region.getLast();
    const currentValue = map.items[currentPos.y].items[currentPos.x];

    if (currentPos.y > 0) {
        const newPos = alloc.create(Pos) catch unreachable;
        newPos.x = currentPos.x;
        newPos.y = currentPos.y - 1;

        if (map.items[newPos.y].items[newPos.x] != currentValue or includedInRegion(region, newPos)) {
            alloc.destroy(newPos);
        } else {
            region.append(newPos) catch unreachable;

            walk(alloc, map, region);
        }
    }

    if (currentPos.x < map.items[0].items.len - 1) {
        const newPos = alloc.create(Pos) catch unreachable;
        newPos.x = currentPos.x + 1;
        newPos.y = currentPos.y;

        if (map.items[newPos.y].items[newPos.x] != currentValue or includedInRegion(region, newPos)) {
            alloc.destroy(newPos);
        } else {
            region.append(newPos) catch unreachable;

            walk(alloc, map, region);
        }
    }

    if (currentPos.y < map.items.len - 1) {
        const newPos = alloc.create(Pos) catch unreachable;
        newPos.x = currentPos.x;
        newPos.y = currentPos.y + 1;

        if (map.items[newPos.y].items[newPos.x] != currentValue or includedInRegion(region, newPos)) {
            alloc.destroy(newPos);
        } else {
            region.append(newPos) catch unreachable;

            walk(alloc, map, region);
        }
    }

    if (currentPos.x > 0) {
        const newPos = alloc.create(Pos) catch unreachable;
        newPos.x = currentPos.x - 1;
        newPos.y = currentPos.y;

        if (map.items[newPos.y].items[newPos.x] != currentValue or includedInRegion(region, newPos)) {
            alloc.destroy(newPos);
        } else {
            region.append(newPos) catch unreachable;

            walk(alloc, map, region);
        }
    }
}

fn startRegion(alloc: *const Alloc, map: *const Map, start: *const Pos) *Region {
    var region = Region.init(alloc.*);

    region.append(start) catch unreachable;

    walk(alloc, map, &region);

    return &region;
}

fn calculatePerimeter(alloc: *const Alloc, map: *const Map, regions: *const RegionsList, regionIdx: u32) u32 {
    var sum: u32 = 0;
    const currentRegion: Region = regions.items[regionIdx];

    // for (currentRegion.items) |pos| {
    //     std.debug.print("{},{}\n", .{ pos.x, pos.y });
    // }

    const newPos = alloc.create(Pos) catch unreachable;
    defer alloc.destroy(newPos);

    for (currentRegion.items) |pos| {
        newPos.x = pos.x;
        newPos.y = pos.y;

        var localSum: u8 = 4;
        // std.debug.print("{d} {d} ", .{ pos.x, pos.y });

        if (pos.y > 0) {
            newPos.y -= 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
                // std.debug.print("up ", .{});
            }

            newPos.y = pos.y;
        }

        if (pos.x > 0) {
            newPos.x -= 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
                // std.debug.print("left ", .{});
            }

            newPos.x = pos.x;
        }

        if (pos.y < map.items.len - 1) {
            newPos.y += 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
                // std.debug.print("bottom ", .{});
            }

            newPos.y = pos.y;
        }

        if (pos.x < map.items[pos.y].items.len - 1) {
            newPos.x += 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
                // std.debug.print("right ", .{});
            }

            newPos.x = pos.x;
        }

        // std.debug.print("\n", .{});
        sum += localSum;
    }

    return sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    // const input =
    //     \\RRRRIICCFF
    //     \\RRRRIICCCF
    //     \\VVRRRCCFFF
    //     \\VVRCCCJFFF
    //     \\VVVVCJJCFE
    //     \\VVIVCCJJEE
    //     \\VVIIICJJEE
    //     \\MIIIIIJJEE
    //     \\MIIISIJEEE
    //     \\MMMISSJEEE
    // ;

    // const input =
    //     // \\.....
    //     // \\.....
    //     // \\M....
    //     // \\M....
    //     // \\MMM..
    //
    //     // \\......
    //     // \\......
    //     // \\......
    //     // \\M.....
    //     // \\M.....
    //     // \\MMM...
    //
    //     // \\..........
    //     // \\..........
    //     // \\..........
    //     // \\..........
    //     // \\..........
    //     // \\..........
    //     // \\..........
    //     // \\M.........
    //     // \\M.........
    //     // \\MMM.......
    //
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var map = Map.init(alloc);

    var lineIter = std.mem.splitScalar(u8, input, '\n');
    while (lineIter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var row = Row.initCapacity(alloc, line.len) catch unreachable;

        for (line) |c| {
            row.appendAssumeCapacity(c);
        }

        map.append(row) catch unreachable;
    }

    var regions = RegionsList.init(alloc);

    for (0..map.items.len) |y| {
        outer: for (0..map.items[y].items.len) |x| {
            const pos = alloc.create(Pos) catch unreachable;
            pos.x = @intCast(x);
            pos.y = @intCast(y);

            for (regions.items) |*region| {
                if (includedInRegion(region, pos)) {
                    continue :outer;
                }
            }

            var region = Region.init(alloc);

            region.append(pos) catch unreachable;

            walk(&alloc, &map, &region);

            regions.append(region) catch unreachable;
        }
    }

    var sum: u64 = 0;
    for (regions.items, 0..) |region, i| {

        // for (region.items) |p| {
        //     std.debug.print("({d}, {d})\n", .{ p.x, p.y });
        // }

        const firstPos = region.items[0];
        const r = map.items[firstPos.y].items[firstPos.x];

        if (r == '.') {
            continue;
        }

        const area = region.items.len;
        const perimeter = calculatePerimeter(&alloc, &map, &regions, @intCast(i));
        const price = area * perimeter;

        // std.debug.print("{c}: {} * {} = {}\n", .{ r, area, perimeter, price });

        sum += price;

        // std.debug.print("\n\n", .{});
    }

    std.debug.print("{}\n", .{sum});
}
