const std = @import("std");

const Pos = struct {
    x: u64,
    y: u64,
};

fn doTheThing(a: u64, b: u64, c: u64, d: u64) f64 {
    const firstDiag: f64 = @floatFromInt(a * b);
    const secondDiag: f64 = @floatFromInt(c * d);
    return firstDiag - secondDiag;
}

fn hasDigitsAfterComma(x: f64) bool {
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

    var tokens: u64 = 0;

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
            .x = std.fmt.parseUnsigned(u64, buttonAString[12..14], 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u64, buttonAString[18..20], 10) catch unreachable,
        };
        const buttonBPos: Pos = .{
            .x = std.fmt.parseUnsigned(u64, buttonBString[12..14], 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u64, buttonBString[18..20], 10) catch unreachable,
        };

        var prizeIter = std.mem.splitSequence(u8, prizeString[7..], ", ");
        const prizeXString = prizeIter.next().?[2..];
        const prizeYString = prizeIter.next().?[2..];

        var prizePos: Pos = .{
            .x = std.fmt.parseUnsigned(u64, prizeXString, 10) catch unreachable,
            .y = std.fmt.parseUnsigned(u64, prizeYString, 10) catch unreachable,
        };

        prizePos.x += 10000000000000;
        prizePos.y += 10000000000000;

        const D = doTheThing(buttonAPos.x, buttonBPos.y, buttonAPos.y, buttonBPos.x);

        std.debug.assert(D != 0.0);

        const D1 = doTheThing(prizePos.x, buttonBPos.y, prizePos.y, buttonBPos.x);
        const D2 = doTheThing(prizePos.y, buttonAPos.x, prizePos.x, buttonAPos.y);

        @setFloatMode(.optimized);
        const x = D1 / D;
        const y = D2 / D;

        if (hasDigitsAfterComma(x) or hasDigitsAfterComma(y)) {
            continue;
        }

        tokens += @as(u64, @intFromFloat(x)) * 3 + @as(u64, @intFromFloat(y));
    }

    std.debug.print("sum = {}\n", .{tokens});
}
