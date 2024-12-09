const std = @import("std");

const print = std.debug.print;

const Block = struct {
    value: ?u64,
};

var EmptyBlock: Block = .{ .value = null };

const Disk = std.ArrayList(*Block);

fn printDisk(disk: *Disk) void {
    for (disk.items) |block| {
        if (block.value) |blockId| {
            print("{}", .{blockId});
        } else {
            print(".", .{});
        }
    }
    print("\n", .{});
}

fn findNextEmptySpot(disk: *Disk, start: usize) usize {
    for (start..disk.items.len) |i| {
        const block = disk.items[i];

        if (block.value == null) {
            return i;
        }
    }

    std.debug.assert(false);

    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // const input = "2333133121414131402";
    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const input = try file.readToEndAlloc(alloc, 32000);
    defer alloc.free(input);

    var disk = Disk.init(alloc);
    defer {
        for (disk.items) |block| {
            alloc.destroy(block);
        }

        disk.deinit();
    }

    var isFileBlock = true;
    var fileBlockId: u64 = 0;

    for (input) |c| {
        if (c == '\n') {
            break;
        }

        std.debug.assert(std.ascii.isDigit(c));

        const number = c - 48;

        for (0..number) |_| {
            const b = alloc.create(Block) catch unreachable;

            b.*.value = if (isFileBlock) fileBlockId else null;

            try disk.append(b);
        }

        if (isFileBlock) {
            fileBlockId += 1;
        }

        isFileBlock = !isFileBlock;
    }

    print("{d}\n", .{disk.items.len});

    var prevEmptySpot: usize = 0;
    var reversedI: usize = disk.items.len;
    while (reversedI > 0) {
        reversedI -= 1;

        const blockPtr = disk.items[reversedI];
        if (blockPtr.value) |_| {
            const emptySpot = findNextEmptySpot(&disk, prevEmptySpot);

            if (reversedI + 1 == emptySpot) {
                break;
            }

            prevEmptySpot = emptySpot;

            const emptyBlock = disk.items[emptySpot];
            disk.items[emptySpot] = blockPtr;
            disk.items[reversedI] = emptyBlock;
        }

        // printDisk(&disk);
    }

    var sum1: u64 = 0;
    for (disk.items, 0..) |block, index| {
        if (block.value) |blockId| {
            sum1 += index * blockId;
        } else {
            break;
        }
    }

    print("1 part - {}\n", .{sum1});
}
