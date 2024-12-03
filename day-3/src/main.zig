const std = @import("std");

const print = std.debug.print;

const State = struct {
    const Level = enum {
        Idle,
        M,
        U,
        L,
        BO,
        D,
        C,
        BC,
    };

    level: Level,
    buf: [3]u8,
    currentBufIdx: u8,
    num: ?u32,
};

fn cmpAndSetState(state: *State, newState: State.Level, c: u8, a: u8) void {
    state.*.currentBufIdx = 0;
    state.buf = undefined;

    if (c == a) {
        state.*.level = newState;
    } else {
        state.*.level = .Idle;
    }
}

fn resetState(state: *State) void {
    state.*.buf = undefined;
    state.*.currentBufIdx = 0;
    state.*.num = null;
    state.*.level = .Idle;
}

fn parse(state: *State, input: []const u8) !u32 {
    var sum: u32 = 0;
    var i: u32 = 0;

    while (i < input.len) : (i += 1) {
        const c = input[i];
        // print("{c} - {any}\n", .{ c, state });

        switch (state.level) {
            .Idle => cmpAndSetState(state, .M, c, 'm'),
            .M => cmpAndSetState(state, .U, c, 'u'),
            .U => cmpAndSetState(state, .L, c, 'l'),
            .L => cmpAndSetState(state, .BO, c, '('),
            .BO => {
                switch (c) {
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                        state.*.level = .D;

                        if (state.currentBufIdx < 3) {
                            state.*.buf[state.currentBufIdx] = c;
                            state.*.currentBufIdx += 1;
                        } else {
                            resetState(state);
                        }
                    },
                    else => {
                        resetState(state);
                    },
                }
            },
            .D => {
                switch (c) {
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                        state.*.level = .D;

                        if (state.currentBufIdx < 3) {
                            state.*.buf[state.currentBufIdx] = c;
                            state.*.currentBufIdx += 1;
                        } else {
                            resetState(state);
                        }
                    },
                    ',' => {
                        if (state.num == null) {
                            state.*.level = .C;
                        } else {
                            resetState(state);
                        }
                    },
                    ')' => {
                        if (state.num != null) {
                            state.*.level = .BC;
                            i -= 1;
                        } else {
                            resetState(state);
                        }
                    },
                    else => resetState(state),
                }
            },
            .C => {
                if (state.currentBufIdx > 0) {
                    const numStr = state.buf[0..state.currentBufIdx];

                    if (std.fmt.parseInt(u32, numStr, 10)) |num| {
                        resetState(state);

                        state.*.num = num;
                        state.*.level = .D;

                        // print("parsed first num: {}\n", .{num});
                    } else |_| {
                        print("parsed wrong numbers? {s}\n", .{numStr});
                        return error.WrongNumbers;
                    }

                    i -= 1;
                } else {
                    resetState(state);
                }
            },
            .BC => {
                if (state.currentBufIdx > 0) {
                    const numStr = state.buf[0..state.currentBufIdx];

                    if (std.fmt.parseInt(u32, numStr, 10)) |num| {
                        // print("parsed second num: {}\n", .{num});
                        // print("making sum: {}\n\n", .{state.num.? * num});
                        // print("{} {}\n", .{ state.num.?, num });
                        sum += state.num.? * num;
                    } else |_| {
                        print("parsed wrong numbers? {s}\n", .{numStr});
                        return error.WrongNumbers;
                    }
                }

                resetState(state);
            },
        }
    }

    return sum;
}

pub fn main() !void {
    var state: State = .{
        .level = .Idle,
        .buf = undefined,
        .currentBufIdx = 0,
        .num = null,
    };

    var sum: u32 = 0;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var buf: [32000]u8 = undefined;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sum += try parse(&state, line);
    }

    print("{}\n", .{sum});
}
