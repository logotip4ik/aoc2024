const std = @import("std");

const print = std.debug.print;

const CharList = std.ArrayList(u8);
const LinesList = std.ArrayList(CharList);
const Pos = struct {
    x: u32,
    y: u32,
};
const Dir = enum {
    Up,
    UpRight,
    Right,
    BottomRight,
    Bottom,
    BottomLeft,
    Left,
    UpLeft,
};

fn getCharForIdx(idx: u8) u8 {
    std.debug.assert(idx < 4);

    return switch (idx) {
        0 => 'X',
        1 => 'M',
        2 => 'A',
        3 => 'S',
        else => 'X',
    };
}

fn isXmas(
    lines: *LinesList,
    pos: Pos,
    offset: u8,
    dir: Dir,
) bool {
    const neededChar = getCharForIdx(offset);

    switch (dir) {
        .Up => {
            const yOffset = @as(i32, @intCast(offset)) * -1;
            const computedYPos = @as(i32, @intCast(pos.y)) + yOffset;
            if (computedYPos < 0) {
                return false;
            }

            const currentChar = lines.items[@as(u32, @intCast(computedYPos))].items[pos.x];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .UpRight => {
            const yOffset = @as(i32, @intCast(offset)) * -1;
            const computedYPos = @as(i32, @intCast(pos.y)) + yOffset;
            if (computedYPos < 0) {
                return false;
            }

            const computedXPos = pos.x + offset;
            if (computedXPos >= lines.items[0].items.len) {
                return false;
            }

            const currentChar = lines.items[@as(u32, @intCast(computedYPos))].items[computedXPos];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .Right => {
            const computedXPos = pos.x + offset;
            if (computedXPos >= lines.items[0].items.len) {
                return false;
            }

            const currentChar = lines.items[pos.y].items[computedXPos];

            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .BottomRight => {
            const computedYPos = pos.y + offset;
            if (computedYPos >= lines.items.len) {
                return false;
            }

            const computedXPos = pos.x + offset;
            if (computedXPos >= lines.items[computedYPos].items.len) {
                return false;
            }

            const currentChar = lines.items[computedYPos].items[computedXPos];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .Bottom => {
            const computedYPos = pos.y + offset;
            if (computedYPos >= lines.items.len) {
                return false;
            }

            const currentChar = lines.items[computedYPos].items[pos.x];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .BottomLeft => {
            const computedYPos = pos.y + offset;
            if (computedYPos >= lines.items.len) {
                return false;
            }

            const xOffset = @as(i32, @intCast(offset)) * -1;
            const computedXPos = @as(i32, @intCast(pos.x)) + xOffset;
            if (computedXPos < 0) {
                return false;
            }

            const currentChar = lines.items[computedYPos].items[@as(u32, @intCast(computedXPos))];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .Left => {
            const xOffset = @as(i32, @intCast(offset)) * -1;
            const computedXPos = @as(i32, @intCast(pos.x)) + xOffset;
            if (computedXPos < 0) {
                return false;
            }

            const currentChar = lines.items[pos.y].items[@as(u32, @intCast(computedXPos))];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },

        .UpLeft => {
            const yOffset = @as(i32, @intCast(offset)) * -1;
            const computedYPos = @as(i32, @intCast(pos.y)) + yOffset;
            if (computedYPos < 0) {
                return false;
            }

            const xOffset = @as(i32, @intCast(offset)) * -1;
            const computedXPos = @as(i32, @intCast(pos.x)) + xOffset;
            if (computedXPos < 0) {
                return false;
            }

            const currentChar = lines.items[@as(u32, @intCast(computedYPos))].items[@as(u16, @intCast(computedXPos))];
            if (currentChar != neededChar) {
                return false;
            }

            return if (offset == 3) true else isXmas(lines, pos, offset + 1, dir);
        },
    }
}

test {
    const testing = std.testing;

    var lines = try LinesList.initCapacity(testing.allocator, 4);
    defer {
        for (lines.items) |item| {
            item.deinit();
        }

        lines.deinit();
    }

    var chars1 = CharList.init(testing.allocator);
    try chars1.append('S');
    try chars1.append(' ');
    try chars1.append(' ');
    try chars1.append('X');
    lines.appendAssumeCapacity(chars1);

    var chars2 = CharList.init(testing.allocator);
    try chars2.append(' ');
    try chars2.append('A');
    try chars2.append('M');
    try chars2.append(' ');
    lines.appendAssumeCapacity(chars2);

    var chars3 = CharList.init(testing.allocator);
    try chars3.append(' ');
    try chars3.append('A');
    try chars3.append('M');
    try chars3.append(' ');
    lines.appendAssumeCapacity(chars3);

    var chars4 = CharList.init(testing.allocator);
    try chars4.append(' ');
    try chars4.append(' ');
    try chars4.append(' ');
    try chars4.append('X');
    lines.appendAssumeCapacity(chars4);

    try testing.expect(
        isXmas(&lines, .{ .x = 3, .y = 3 }, 0, .UpLeft) == false,
    );
}

fn countXmas(lines: *LinesList, pos: Pos) u32 {
    var sum: u32 = 0;

    inline for (std.meta.fields(Dir)) |f| {
        if (isXmas(lines, pos, 0, @enumFromInt(f.value))) {
            sum += 1;
        }
    }

    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input =
    //     \\MMMSXXMASM
    //     \\MSAMXMSMSA
    //     \\AMXSXMAAMM
    //     \\MSAMASMSMX
    //     \\XMASAMXAMM
    //     \\XXAMMXXAMA
    //     \\SMSMSASXSS
    //     \\SAXAMASAAA
    //     \\MAMMMXMMMM
    //     \\MXMXAXMASX
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    const linesCount = std.mem.count(u8, input, "\n");
    var lines = try LinesList.initCapacity(alloc, linesCount);
    defer {
        for (lines.items) |item| {
            item.deinit();
        }

        lines.deinit();
    }

    var linesIter = std.mem.splitSequence(u8, input, "\n");
    var lineIdx: u32 = 0;
    while (linesIter.next()) |line| : (lineIdx += 1) {
        if (line.len == 0) {
            continue;
        }

        var chars = try CharList.initCapacity(alloc, line.len);

        for (line) |c| {
            chars.appendAssumeCapacity(c);
        }

        lines.appendAssumeCapacity(chars);
    }

    var sum: u32 = 0;

    for (0..lines.items.len) |i| {
        for (0..lines.items[0].items.len) |j| {
            const count = countXmas(&lines, .{
                .x = @as(u32, @intCast(j)),
                .y = @as(u32, @intCast(i)),
            });
            sum += count;
        }
    }

    print("{}\n", .{sum});
}
