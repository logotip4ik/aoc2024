const std = @import("std");

const Alloc = std.mem.Allocator;

const Row = std.ArrayList(u8);
const Map = std.ArrayList(Row);

const Pos = struct {
    x: u16,
    y: u16,
};

const PosWithSide = struct {
    x: u16,
    y: u16,
    side: enum { Up, Right, Bottom, Left },
};

const RegionMeta = struct {
    area: u32,
    sides: u32,
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

    const newPos = alloc.create(Pos) catch unreachable;
    defer alloc.destroy(newPos);

    for (currentRegion.items) |pos| {
        newPos.x = pos.x;
        newPos.y = pos.y;

        var localSum: u8 = 4;

        if (pos.y > 0) {
            newPos.y -= 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
            }

            newPos.y = pos.y;
        }

        if (pos.x > 0) {
            newPos.x -= 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
            }

            newPos.x = pos.x;
        }

        if (pos.y < map.items.len - 1) {
            newPos.y += 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
            }

            newPos.y = pos.y;
        }

        if (pos.x < map.items[pos.y].items.len - 1) {
            newPos.x += 1;

            if (includedInRegion(&currentRegion, newPos)) {
                localSum -= 1;
            }

            newPos.x = pos.x;
        }

        sum += localSum;
    }

    return sum;
}

fn isPosInsideRegion(pos: *const Pos, region: *const Region, map: *const Map) bool {
    if (pos.x == 0 or pos.y == 0) {
        return false;
    }

    if (pos.y == map.items.len - 1 or pos.x == map.items[pos.y].items.len - 1) {
        return false;
    }

    const offsets = &[_]struct { x: i8, y: i8 }{
        .{ .x = 0, .y = -1 },
        .{ .x = 1, .y = 0 },
        .{ .x = 0, .y = 1 },
        .{ .x = -1, .y = 0 },
    };

    var p: Pos = undefined;
    inline for (offsets) |offset| {
        const newX = @as(i32, @intCast(pos.x)) + offset.x;
        const newY = @as(i32, @intCast(pos.y)) + offset.y;
        p.x = @intCast(newX);
        p.y = @intCast(newY);

        if (includedInRegion(region, &p)) {
            return true;
        }
    }

    return false;
}

fn findOuterPoint(region: *const Region) *Pos {
    var outer = region.items[0];

    for (region.items[1..]) |pos| {
        if (pos.x < outer.x and pos.y < outer.y) {
            outer = pos;
            continue;
        }

        if (pos.y < outer.y) {
            outer = pos;
        }
    }

    return outer;
}

fn calculateSides(map: *const Map, region: *const Region) struct {
    sides: u16,
    insideRegionX: ?u16,
    insideRegionY: ?u16,
} {
    var outerPoint = findOuterPoint(region).*;
    const firstPoint = outerPoint;

    var inside: ?u8 = null;
    if (firstPoint.y > 0) {
        inside = map.items[firstPoint.y - 1].items[firstPoint.x];
    }

    var sides: u16 = 0;
    var facing: enum { Up, Right, Bottom, Left } = .Up;

    var tempPos: Pos = undefined;
    while (true) {
        switch (facing) {
            .Up => sw: {
                if (outerPoint.y > 0) {
                    tempPos.x = outerPoint.x;
                    tempPos.y = outerPoint.y - 1;

                    // tempPos.x = outerPoint.x + 1;
                    // tempPos.y = outerPoint.y - 1;

                    if (includedInRegion(region, &tempPos)) {
                        outerPoint = tempPos;
                        facing = .Left;
                        sides += 1;
                        break :sw;
                    }
                }

                tempPos.x = outerPoint.x + 1;
                tempPos.y = outerPoint.y;

                if (includedInRegion(region, &tempPos)) {
                    outerPoint = tempPos;
                    break :sw;
                }

                facing = .Right;
                sides += 1;
            },

            .Right => sw: {
                tempPos.x = outerPoint.x + 1;
                tempPos.y = outerPoint.y;

                // tempPos.x = outerPoint.x + 1;
                // tempPos.y = outerPoint.y + 1;

                if (includedInRegion(region, &tempPos)) {
                    outerPoint = tempPos;
                    facing = .Up;
                    sides += 1;
                    break :sw;
                }

                tempPos.x = outerPoint.x;
                tempPos.y = outerPoint.y + 1;

                if (includedInRegion(region, &tempPos)) {
                    outerPoint = tempPos;
                    break :sw;
                }

                facing = .Bottom;
                sides += 1;
            },

            .Bottom => sw: {
                tempPos.x = outerPoint.x;
                tempPos.y = outerPoint.y + 1;

                if (includedInRegion(region, &tempPos)) {
                    outerPoint = tempPos;
                    facing = .Right;
                    sides += 1;
                    break :sw;
                }

                if (outerPoint.x > 0) {
                    // tempPos.x = outerPoint.x - 1;
                    // tempPos.y = outerPoint.y + 1;
                    //
                    // if (includedInRegion(region, &tempPos)) {
                    //     outerPoint = tempPos;
                    //     facing = .Right;
                    //     sides += 1;
                    //     break :sw;
                    // }

                    tempPos.x = outerPoint.x - 1;
                    tempPos.y = outerPoint.y;

                    if (includedInRegion(region, &tempPos)) {
                        outerPoint = tempPos;
                        break :sw;
                    }
                }

                facing = .Left;
                sides += 1;
            },

            .Left => sw: {
                if (outerPoint.x > 0) {
                    tempPos.x = outerPoint.x - 1;
                    tempPos.y = outerPoint.y;

                    // if (outerPoint.x > 0 and outerPoint.y > 0) {
                    //     tempPos.x = outerPoint.x - 1;
                    //     tempPos.y = outerPoint.y - 1;

                    if (includedInRegion(region, &tempPos)) {
                        outerPoint = tempPos;
                        facing = .Bottom;
                        sides += 1;
                        break :sw;
                    }
                }

                if (outerPoint.y > 0) {
                    tempPos.x = outerPoint.x;
                    tempPos.y = outerPoint.y - 1;

                    if (includedInRegion(region, &tempPos)) {
                        outerPoint = tempPos;
                        break :sw;
                    }
                }

                facing = .Up;
                sides += 1;
            },
        }

        if (inside != null) {
            switch (facing) {
                .Up => blk: {
                    if (outerPoint.y == 0) {
                        inside = null;
                        break :blk;
                    }

                    const newInside = map.items[outerPoint.y - 1].items[outerPoint.x];
                    if (newInside != inside) {
                        inside = null;
                        break :blk;
                    }
                },

                .Right => blk: {
                    if (outerPoint.x == map.items.len - 1) {
                        inside = null;
                        break :blk;
                    }

                    const newInside = map.items[outerPoint.y].items[outerPoint.x + 1];
                    if (newInside != inside) {
                        inside = null;
                    }
                },

                .Bottom => blk: {
                    if (outerPoint.y == map.items.len - 1) {
                        inside = null;
                        break :blk;
                    }

                    const newInside = map.items[outerPoint.y + 1].items[outerPoint.x];
                    if (newInside != inside) {
                        inside = null;
                    }
                },

                .Left => blk: {
                    if (outerPoint.x == 0) {
                        inside = null;
                        break :blk;
                    }

                    const newInside = map.items[outerPoint.y].items[outerPoint.x - 1];
                    if (newInside != inside) {
                        inside = null;
                    }
                },
            }
        }

        if (outerPoint.x == firstPoint.x and outerPoint.y == firstPoint.y and facing == .Up) {
            break;
        }
    }

    if (inside) |_| {
        return .{
            .sides = sides,
            .insideRegionX = firstPoint.x,
            .insideRegionY = firstPoint.y - 1,
        };
    } else {
        return .{
            .sides = sides,
            .insideRegionX = null,
            .insideRegionY = null,
        };
    }
}

fn isRegionInsideRegion() bool {}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    const input =
        // \\AAAA
        // \\BBCD
        // \\BBCC
        // \\EEEC

        // \\.....
        // \\.AAA.
        // \\.A.A.
        // \\.AA..
        // \\.A.A.
        // \\.AAA.
        // \\.....

        // \\EEEEE
        // \\EXXXX
        // \\EEEEE
        // \\EXXXX
        // \\EEEEE

        // \\OOOOO
        // \\OXOXO
        // \\OOOOO
        // \\OXOXO
        // \\OOOOO

        // \\AAAAAA
        // \\AAABBA
        // \\AAABBA
        // \\ABBAAA
        // \\ABBAAA
        // \\AAAAAA

        // \\......
        // \\.MMMM.
        // \\.MAAM.
        // \\.MAAM.
        // \\.MMMM.
        // \\......

        // \\RRRRIICCFF
        // \\RRRRIICCCF
        // \\VVRRRCCFFF
        // \\VVRCCCJFFF
        // \\VVVVCJJCFE
        // \\VVIVCCJJEE
        // \\VVIIICJJEE
        // \\MIIIIIJJEE
        // \\MIIISIJEEE
        // \\MMMISSJEEE

        // \\CCAAA
        // \\CCAAA
        // \\AABBA
        // \\AAAAA

        \\AAAAAAAA
        \\AACBBDDA
        \\AACBBAAA
        \\ABBAAAAA
        \\ABBADDDA
        \\AAAADADA
        \\AAAAAAAA

        // \\..........
        // \\..........
        // \\..........
        // \\..........
        // \\..........
        // \\..........
        // \\..........
        // \\M.........
        // \\M.........
        // \\MMM.......

    ;

    // const file = try std.fs.cwd().openFile("input", .{});
    // defer file.close();
    // const input = try file.readToEndAlloc(alloc, 32000);
    // defer alloc.free(input);

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

    var regionMeta = std.AutoHashMap(*Region, u32).init(alloc);
    defer regionMeta.deinit();

    for (regions.items) |*region| {
        const firstPos = region.items[0];
        const key = map.items[firstPos.y].items[firstPos.x];
        // if (key == '.') {
        //     continue;
        // }

        const calculations = calculateSides(&map, region);
        regionMeta.putNoClobber(region, calculations.sides) catch unreachable;

        std.debug.print("{c} = {any}\n", .{ key, calculations });

        if (calculations.insideRegionX) |insideX| {
            const outerRegionPos: Pos = .{
                .x = insideX,
                .y = calculations.insideRegionY.?,
            };

            var outerRegion: ?*Region = null;
            for (regions.items) |*r| {
                if (includedInRegion(r, &outerRegionPos)) {
                    outerRegion = r;
                    break;
                }
            }

            const got = regionMeta.getOrPut(outerRegion.?) catch unreachable;
            if (got.found_existing) {
                got.value_ptr.* += calculations.sides;
            } else {
                got.value_ptr.* = calculations.sides;
            }
        }

        // const sides: u16 = calculations[0];
        // const maybeInside: ?u8 = calculations[1];

        // const got = regionMeta.getOrPut(key) catch unreachable;
        //
        // if (got.found_existing) {
        //     got.value_ptr.area = @intCast(region.items.len);
        //     got.value_ptr.sides += sides;
        // } else {
        //     const meta = alloc.create(RegionMeta) catch unreachable;
        //     meta.area = @intCast(region.items.len);
        //     meta.sides = sides;
        //     got.value_ptr.* = meta.*;
        // }
        //
        // if (maybeInside) |inside| {
        //     const insideGot = regionMeta.getOrPut(inside) catch unreachable;
        //
        //     if (insideGot.found_existing) {
        //         insideGot.value_ptr.sides += sides;
        //     } else {
        //         const meta = alloc.create(RegionMeta) catch unreachable;
        //         meta.sides = sides;
        //         insideGot.value_ptr.* = meta.*;
        //     }
        // }
    }

    var sum: u64 = 0;

    var regionMetaIter = regionMeta.iterator();
    while (regionMetaIter.next()) |entry| {
        const region = entry.key_ptr.*;
        const firstPoint = region.items[0];

        const key = map.items[firstPoint.y].items[firstPoint.x];

        const area = region.items.len;
        const sides = entry.value_ptr.*;

        const price = area * sides;

        std.debug.print("{c}: {} * {} = {}\n", .{ key, area, sides, price });

        sum += price;
    }

    std.debug.print("{}\n", .{sum});
}
