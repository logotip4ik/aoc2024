const std = @import("std");

const Registers = [3]u32;

fn getComboValue(registers: *const Registers, combovalue: u8) u32 {
    return switch (combovalue) {
        0...3 => combovalue,
        4 => registers[0],
        5 => registers[1],
        6 => registers[2],
        else => @panic("unknown combovalue passed to resolve"),
    };
}

pub fn main() !void {
    //

    // const input =
    //     \\Register A: 729
    //     \\Register B: 0
    //     \\Register C: 0
    //     \\
    //     \\Program: 0,1,5,4,3,0
    // ;

    // const input =
    //     \\Register A: 0
    //     \\Register B: 2024
    //     \\Register C: 43690
    //     \\
    //     \\Program: 4,0
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var inputBuf: [1000]u8 = undefined;
    const inputLen = try file.readAll(&inputBuf);
    const input = inputBuf[0..inputLen];

    var registers: Registers = .{ 0, 0, 0 };
    var programBuf: [16]u8 = undefined;
    var outputBuf: [1000]u32 = undefined;
    var outputI: u32 = 0;

    var lineIter = std.mem.splitScalar(u8, input, '\n');

    const register0Line = lineIter.next().?;
    registers[0] = std.fmt.parseUnsigned(u32, register0Line[12..], 10) catch unreachable;

    const register1Line = lineIter.next().?;
    registers[1] = std.fmt.parseUnsigned(u32, register1Line[12..], 10) catch unreachable;

    const register2Line = lineIter.next().?;
    registers[2] = std.fmt.parseUnsigned(u32, register2Line[12..], 10) catch unreachable;

    // empty line
    _ = lineIter.next();

    var programI: u32 = 0;
    const programLine = lineIter.next().?;
    var programIter = std.mem.splitScalar(u8, programLine[9..], ',');
    while (programIter.next()) |op| : (programI += 1) {
        programBuf[programI] = std.fmt.parseUnsigned(u8, op, 10) catch unreachable;
    }

    const program = programBuf[0..programI];

    std.debug.print("r1 - {}\nop - {d}\n", .{ registers[0], program });
    var i: u32 = 0;

    while (i < program.len) {
        const op = program[i];

        switch (op) {
            0 => {
                const numerator = registers[0];
                const denominator = std.math.pow(u32, 2, getComboValue(&registers, program[i + 1]));

                registers[0] = @divTrunc(numerator, denominator);
            },
            1 => {
                registers[1] ^= program[i + 1];
            },
            2 => {
                const combovalue = getComboValue(&registers, program[i + 1]);
                const value = @mod(combovalue, 8);

                registers[1] = value;
            },
            3 => blk: {
                const A = registers[0];
                if (A == 0) {
                    break :blk;
                }

                i = program[i + 1];
                continue;
            },
            4 => {
                registers[1] ^= registers[2];
            },
            5 => {
                const combovalue = getComboValue(&registers, program[i + 1]);
                const value = @mod(combovalue, 8);

                outputBuf[outputI] = value;
                outputI += 1;
            },
            6 => {
                const numerator = registers[0];
                const denominator = std.math.pow(u32, 2, getComboValue(&registers, program[i + 1]));

                registers[1] = @divTrunc(numerator, denominator);
            },
            7 => {
                const numerator = registers[0];
                const denominator = std.math.pow(u32, 2, getComboValue(&registers, program[i + 1]));

                registers[2] = @divTrunc(numerator, denominator);
            },
            else => {
                @panic("unknown operation");
            },
        }

        i += 2;
    }

    std.debug.print("registers - {d}\n", .{registers});
    std.debug.print("output - {d}\n", .{outputBuf[0..outputI]});
}
