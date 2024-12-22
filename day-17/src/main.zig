const std = @import("std");

const Registers = [3]u64;

inline fn getComboValue(registers: *const Registers, combovalue: u8) u64 {
    return switch (combovalue) {
        0...3 => combovalue,
        4 => registers[0],
        5 => registers[1],
        6 => registers[2],
        else => @panic("unknown combovalue passed to resolve"),
    };
}

fn find(registersCopy: Registers, program: [32]u8, programEnd: u8, startingA: u64, endA: u64) void {
    const programVec: @Vector(32, u8) = program;
    const programI = programEnd;

    var registers = registersCopy;
    var outputI: u8 = 0;
    var outputBuf: [32]u8 = undefined;
    var foundRes = false;

    var checkingA: u64 = startingA;
    while (true) : (checkingA += 1) {
        registers[0] = checkingA;
        registers[1] = 0;
        registers[2] = 0;

        outputI = 0;
        @memset(&outputBuf, 0);

        var i: u64 = 0;
        while (i < program.len) {
            const op = program[i];

            switch (op) {
                0 => {
                    const numerator = registers[0];
                    const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));

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

                    outputBuf[outputI] = @intCast(value);
                    outputI += 1;
                },
                6 => {
                    const numerator = registers[0];
                    const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));

                    registers[1] = @divTrunc(numerator, denominator);
                },
                7 => {
                    const numerator = registers[0];
                    const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));

                    registers[2] = @divTrunc(numerator, denominator);
                },
                else => {
                    @panic("unknown operation");
                },
            }

            i += 2;
        }

        if (outputI > programI) {
            // std.debug.print("wrong number? \n", .{});
            break;
        }

        const outputVec: @Vector(32, u64) = outputBuf;

        if (@reduce(.And, outputVec == programVec)) {
            foundRes = true;
            break;
        }

        if (checkingA == endA) {
            // std.debug.print("{},{}\n", .{ outputI, programI });
            // std.debug.print("too many tries ?\n", .{});
            break;
        }
    }

    if (foundRes) {
        std.debug.print("output - {d}\n", .{outputBuf[0..outputI]});
        std.debug.print("a: {d}\n", .{checkingA});
    }
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

    // const input =
    //     \\Register A: 117440
    //     \\Register B: 0
    //     \\Register C: 0
    //     \\
    //     \\Program: 0,3,5,4,3,0
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    var inputBuf: [1000]u8 = undefined;
    const inputLen = try file.readAll(&inputBuf);
    const input = inputBuf[0..inputLen];

    var registers: Registers = .{ 0, 0, 0 };
    var programBuf: [32]u8 = undefined;
    @memset(&programBuf, 0);
    // var outputBuf: [32]u64 = undefined;
    // var outputI: u64 = 0;

    var lineIter = std.mem.splitScalar(u8, input, '\n');

    const register0Line = lineIter.next().?;
    registers[0] = std.fmt.parseUnsigned(u64, register0Line[12..], 10) catch unreachable;

    const register1Line = lineIter.next().?;
    registers[1] = std.fmt.parseUnsigned(u64, register1Line[12..], 10) catch unreachable;

    const register2Line = lineIter.next().?;
    registers[2] = std.fmt.parseUnsigned(u64, register2Line[12..], 10) catch unreachable;

    // empty line
    _ = lineIter.next();

    var programI: u8 = 0;
    const programLine = lineIter.next().?;
    var programIter = std.mem.splitScalar(u8, programLine[9..], ',');
    while (programIter.next()) |op| : (programI += 1) {
        programBuf[programI] = std.fmt.parseUnsigned(u8, op, 10) catch unreachable;
    }

    const program = programBuf[0..programI];
    std.debug.print("op - {d}\n", .{program});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    const poolOpt = std.Thread.Pool.Options{
        .allocator = alloc,
        .n_jobs = 12,
    };
    var pool: std.Thread.Pool = undefined;
    _ = try pool.init(poolOpt);
    defer pool.deinit();

    var checkingA: u64 = 100000000000000;
    const stopA = 1000000000000000;
    const step = 100000000;
    while (checkingA < stopA) {
        try pool.spawn(find, .{ registers, programBuf, programI, checkingA, checkingA + step });

        checkingA += step;
    }

    // const programVec: @Vector(32, u64) = programBuf;

    // var checkingA: u64 = 100000000000000;
    // while (true) : (checkingA += 1) {
    //     registers[0] = checkingA;
    //     registers[1] = 0;
    //     registers[2] = 0;
    //
    //     outputI = 0;
    //     @memset(&outputBuf, 0);
    //
    //     var i: u64 = 0;
    //     while (i < program.len) {
    //         const op = program[i];
    //
    //         switch (op) {
    //             0 => {
    //                 const numerator = registers[0];
    //                 const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));
    //
    //                 registers[0] = @divTrunc(numerator, denominator);
    //             },
    //             1 => {
    //                 registers[1] ^= program[i + 1];
    //             },
    //             2 => {
    //                 const combovalue = getComboValue(&registers, program[i + 1]);
    //                 const value = @mod(combovalue, 8);
    //
    //                 registers[1] = value;
    //             },
    //             3 => blk: {
    //                 const A = registers[0];
    //                 if (A == 0) {
    //                     break :blk;
    //                 }
    //
    //                 i = program[i + 1];
    //                 continue;
    //             },
    //             4 => {
    //                 registers[1] ^= registers[2];
    //             },
    //             5 => {
    //                 const combovalue = getComboValue(&registers, program[i + 1]);
    //                 const value = @mod(combovalue, 8);
    //
    //                 outputBuf[outputI] = value;
    //                 outputI += 1;
    //             },
    //             6 => {
    //                 const numerator = registers[0];
    //                 const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));
    //
    //                 registers[1] = @divTrunc(numerator, denominator);
    //             },
    //             7 => {
    //                 const numerator = registers[0];
    //                 const denominator = std.math.pow(u64, 2, getComboValue(&registers, program[i + 1]));
    //
    //                 registers[2] = @divTrunc(numerator, denominator);
    //             },
    //             else => {
    //                 @panic("unknown operation");
    //             },
    //         }
    //
    //         i += 2;
    //     }
    //
    //     // std.debug.print("outputi - {d}\n", .{outputI});
    //     // if (true) {
    //     //     break;
    //     // }
    //
    //     // const output = outputBuf[0..outputI];
    //     // if (checkingA % 50000 == 0) {
    //     //     std.debug.print("a - {d}\ninput - {d}\noutput - {d}\n\n", .{ checkingA, program, output });
    //     // }
    //
    //     if (outputI > programI) {
    //         std.debug.print("wrong number? \n", .{});
    //         break;
    //     }
    //
    //     const outputVec: @Vector(32, u64) = outputBuf;
    //
    //     if (@reduce(.And, outputVec == programVec)) {
    //         break;
    //     }
    //
    //     if (checkingA == std.math.maxInt(u64)) {
    //         // std.debug.print("{},{}\n", .{ outputI, programI });
    //         std.debug.print("too many tries ?\n", .{});
    //         break;
    //     }
    //
    //     // const outputVec: @Vector(32, u64) = outputBuf;
    //     // const programVec: @Vector(32, u64) = programBuf;
    //
    //     // if (@reduce(.And, outputVec == programVec)) {
    //     //     break;
    //     // }
    //
    // }
    //
    // std.debug.print("output - {d}\n", .{outputBuf[0..outputI]});
    // std.debug.print("a: {d}\n", .{checkingA});
}
