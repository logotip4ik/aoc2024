const std = @import("std");

const PosWithVelocity = struct {
    x: u8,
    y: u8,

    vx: i8,
    vy: i8,
};

const ROOM_WIDTH = 101;
const ROOM_HEIGHT = 103;

fn apply(robot: *PosWithVelocity, times: u32) void {
    var newX = @as(i64, @intCast(robot.x)) + @as(i64, @intCast(robot.vx)) * @as(i64, @intCast(times));
    var newY = @as(i64, @intCast(robot.y)) + @as(i64, @intCast(robot.vy)) * @as(i64, @intCast(times));

    newX += ROOM_WIDTH * times;
    newY += ROOM_HEIGHT * times;

    newX = @mod(newX, ROOM_WIDTH);
    newY = @mod(newY, ROOM_HEIGHT);

    robot.x = @intCast(newX);
    robot.y = @intCast(newY);
}

fn printRobots(robots: *const []PosWithVelocity) void {
    for (0..ROOM_HEIGHT) |y| {
        for (0..ROOM_WIDTH) |x| {
            var robotsAtPoint: u16 = 0;

            for (robots.*) |robot| {
                if (robot.x == x and robot.y == y) {
                    robotsAtPoint += 1;
                }
            }

            if (robotsAtPoint == 0) {
                std.debug.print(".", .{});
            } else {
                std.debug.print("{}", .{robotsAtPoint});
            }
        }

        std.debug.print("\n", .{});
    }

    std.debug.print("\n", .{});
}

var robotBuff: [1000]PosWithVelocity = undefined;
var inputBuff: [32000]u8 = undefined;
pub fn main() !void {

    // const input =
    //     \\p=0,4 v=3,-3
    //     \\p=6,3 v=-1,-3
    //     \\p=10,3 v=-1,2
    //     \\p=2,0 v=2,-1
    //     \\p=0,0 v=1,3
    //     \\p=3,0 v=-2,-2
    //     \\p=7,6 v=-1,-3
    //     \\p=3,0 v=-1,-2
    //     \\p=9,3 v=2,3
    //     \\p=7,3 v=-1,2
    //     \\p=2,4 v=2,-3
    //     \\p=9,5 v=-3,-3
    // ;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const inputLen = try file.readAll(&inputBuff);
    const input = inputBuff[0..inputLen];

    var inserted: u16 = 0;

    var lineIter = std.mem.splitScalar(u8, input, '\n');
    while (lineIter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var metaIter = std.mem.splitScalar(u8, line, ' ');

        const pString = metaIter.next().?;
        var pIter = std.mem.splitScalar(u8, pString[2..], ',');

        robotBuff[inserted].x = std.fmt.parseUnsigned(u8, pIter.next().?, 10) catch unreachable;
        robotBuff[inserted].y = std.fmt.parseUnsigned(u8, pIter.next().?, 10) catch unreachable;

        const vString = metaIter.next().?;
        var vIter = std.mem.splitScalar(u8, vString[2..], ',');

        robotBuff[inserted].vx = std.fmt.parseInt(i8, vIter.next().?, 10) catch unreachable;
        robotBuff[inserted].vy = std.fmt.parseInt(i8, vIter.next().?, 10) catch unreachable;

        inserted += 1;
    }

    const robots = robotBuff[0..inserted];

    var q0: u32 = 0;
    var q1: u32 = 0;
    var q2: u32 = 0;
    var q3: u32 = 0;

    const qX = @divFloor(ROOM_WIDTH, 2);
    const qY = @divFloor(ROOM_HEIGHT, 2);

    var i: u32 = 0;
    while (true) : (i += 1) {
        for (robots) |*robot| {
            apply(robot, 1);
        }

        for (robots) |robot| {
            if (robot.x < qX and robot.y < qY) {
                q0 += 1;
                continue;
            }

            if (robot.x > qX and robot.y < qY) {
                q1 += 1;
                continue;
            }

            if (robot.x < qX and robot.y > qY) {
                q2 += 1;
                continue;
            }

            if (robot.x > qX and robot.y > qY) {
                q3 += 1;
                continue;
            }
        }

        const threshold = 278;
        if (q0 > threshold or q1 > threshold or q2 > threshold or q3 > threshold) {
            break;
        }

        q0 = 0;
        q1 = 0;
        q2 = 0;
        q3 = 0;

        if (i > 9999999) {
            std.debug.assert(false);
        }
    }

    std.debug.print("i - {}\n", .{i + 1});
    printRobots(&robots);
}
