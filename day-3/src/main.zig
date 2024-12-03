// I could have used regex engine from c... buuuut i was too lazy to read it's complicated manual,
// so why not to build my own little parser? That should be easier, right?
// This parser is very broken, but it solved both parts... Sorry future me, deal with it
const std = @import("std");

const print = std.debug.print;

const State = struct {
    const Level = enum {
        Idle,

        D,
        O,
        N,
        Quot,
        T,

        M,
        U,
        L,
        Digit,
        C,

        BO,
        BC,
    };

    enabled: bool,
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

        switch (state.level) {
            .Idle => {
                switch (c) {
                    'm' => cmpAndSetState(state, .M, c, 'm'),
                    'd' => cmpAndSetState(state, .D, c, 'd'),
                    else => resetState(state),
                }
            },

            .D => cmpAndSetState(state, .O, c, 'o'),
            .O => {
                switch (c) {
                    '(' => state.level = .BO,
                    'n' => state.level = .N,
                    else => resetState(state),
                }
            },

            .N => cmpAndSetState(state, .Quot, c, '\''),
            .Quot => cmpAndSetState(state, .T, c, 't'),
            .T => cmpAndSetState(state, .BO, c, '('),

            .M => cmpAndSetState(state, .U, c, 'u'),
            .U => cmpAndSetState(state, .L, c, 'l'),
            .L => cmpAndSetState(state, .BO, c, '('),

            .BO => {
                switch (c) {
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                        state.*.level = .Digit;

                        if (state.currentBufIdx < 3) {
                            state.*.buf[state.currentBufIdx] = c;
                            state.*.currentBufIdx += 1;
                        } else {
                            resetState(state);
                        }
                    },
                    ')' => {
                        i -= 1;
                        state.level = .BC;
                    },
                    else => {
                        resetState(state);
                    },
                }
            },
            .Digit => {
                switch (c) {
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                        state.*.level = .Digit;

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
                        state.*.level = .Digit;

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
                const prevChar = input[i - 2];

                if (prevChar == 'o' or prevChar == 't') {
                    state.enabled = if (prevChar == 'o') true else false;
                } else if (state.currentBufIdx > 0 and state.enabled) {
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
        .enabled = true,
        .level = .Idle,
        .buf = undefined,
        .currentBufIdx = 0,
        .num = null,
    };

    var sum: u32 = 0;

    // const input =
    //     \\)mul(542,816):don't()select()from()#(;!select()mul(541,668)
    // ;
    //
    // sum += try parse(&state, input);

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
