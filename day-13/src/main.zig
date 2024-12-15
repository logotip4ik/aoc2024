const std = @import("std");

const Pos = struct {
    x: u32,
    y: u32,
};

fn doTheThing(a: u32, b: u32, c: u32, d: u32) f32 {
    const firstDiag: f32 = @floatFromInt(a * b);
    const secondDiag: f32 = @floatFromInt(c * d);
    return firstDiag - secondDiag;
}

fn hasDigitsAfterComma(x: f32) bool {
    return @floor(x) != x;
}

var buff: [32000]u8 = undefined;
pub fn main() !void {

    // const input =
    //     \\Button A: X+94, Y+34
    //     \\Button B: X+22, Y+67
    //     \\Prize: X=8400, Y=5400
    //     \\
    //     \\Button A: X+26, Y+66
    //     \\Button B: X+67, Y+21
    //     \\Prize: X=12748, Y=12176
    //     \\
    //     \\Button A: X+17, Y+86
    //     \\Button B: X+84, Y+37
    //     \\Prize: X=7870, Y=6450
    //     \\
    //     \\Button A: X+69, Y+23
    //     \\Button B: X+27, Y+71
    //     \\Prize: X=18641, Y=10279
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const inputLen = try file.readAll(&buff);
    const input = buff[0..inputLen];

    var tokens: u32 = 0;

    var machineIter = std.mem.splitSequence(u8, input, "\n\n");
    while (machineIter.next()) |machineString| {
        if (machineString.len == 0) {
            continue;
        }

        var lineIter = std.mem.splitScalar(u8, machineString, '\n');

        const buttonAString = lineIter.next().?;
        const buttonBString = lineIter.next().?;
        const prizeString = lineIter.next().?;

        const buttonAPos: Pos = .{
            .x = std.fmt.parseUnsigned(u32, buttonAString[12..14], 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u32, buttonAString[18..20], 10) catch unreachable,
        };
        const buttonBPos: Pos = .{
            .x = std.fmt.parseUnsigned(u32, buttonBString[12..14], 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u32, buttonBString[18..20], 10) catch unreachable,
        };

        std.debug.print("str - {s}\n", .{prizeString});
        var prizeIter = std.mem.splitSequence(u8, prizeString[7..], ", ");
        const prizeXString = prizeIter.next().?[2..];
        const prizeYString = prizeIter.next().?[2..];

        const prizePos: Pos = .{
            .x = std.fmt.parseUnsigned(u32, prizeXString, 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u32, prizeYString, 10) catch unreachable,
        };

        // const firstDiag: f32 = @floatFromInt(buttonAPos.x * buttonBPos.y);
        // const secondDiag: f32 = @floatFromInt(buttonAPos.y * buttonBPos.x);
        // const D: f32 = firstDiag - secondDiag;

        const D = doTheThing(buttonAPos.x, buttonBPos.y, buttonAPos.y, buttonBPos.x);

        std.debug.assert(D != 0.0);

        // const D1: f32 = @floatFromInt(prizePos.x * buttonBPos.y - buttonBPos.x * prizePos.y);
        // const D2: f32 = @floatFromInt(prizePos.y * buttonAPos.x - buttonAPos.y * prizePos.x);
        const D1 = doTheThing(prizePos.x, buttonBPos.y, prizePos.y, buttonBPos.x);
        const D2 = doTheThing(prizePos.y, buttonAPos.x, prizePos.x, buttonAPos.y);

        @setFloatMode(.optimized);
        const x = D1 / D;
        const y = D2 / D;

        if (hasDigitsAfterComma(x) or hasDigitsAfterComma(y)) {
            std.debug.print("no options for prize winning in\n{}\n{}\n{}\n\n", .{
                buttonAPos,
                buttonBPos,
                prizePos,
            });
            continue;
        }

        if (x > 100 or y > 100) {
            std.debug.print("too many keypresses\n", .{});
            continue;
        }

        tokens += @as(u32, @intFromFloat(x)) * 3 + @as(u32, @intFromFloat(y));

        // std.debug.print("{}\n{}\n{}\n\n", .{ buttonAPos, buttonBPos, prizePos });
    }

    std.debug.print("sum = {}\n", .{tokens});
}
