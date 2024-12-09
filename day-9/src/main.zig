const std = @import("std");

const print = std.debug.print;

const Block = struct {
    value: ?u64,
    size: u64,
};

const Disk = std.ArrayList(*Block);

fn printDisk(disk: *Disk) void {
    for (disk.items) |block| {
        for (0..block.size) |_| {
            if (block.value) |blockId| {
                print("{}", .{blockId});
            } else {
                print(".", .{});
            }
        }
    }

    print("\n", .{});
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

        const b = alloc.create(Block) catch unreachable;
        b.*.value = if (isFileBlock) fileBlockId else null;
        b.*.size = number;

        disk.append(b) catch unreachable;

        if (isFileBlock) {
            fileBlockId += 1;
        }

        isFileBlock = !isFileBlock;
    }

    var reversedI: usize = disk.items.len;
    while (reversedI > 0) {
        reversedI -= 1;

        const lastChunk = disk.items[reversedI];
        if (lastChunk.value == null) {
            continue;
        }

        for (disk.items[0..reversedI], 0..) |block, i| {
            if (block.value == null and block.size >= lastChunk.size) {
                if (block.size - lastChunk.size == 0) {
                    const temp = disk.items[i];
                    disk.items[i] = lastChunk;
                    disk.items[reversedI] = temp;
                } else {
                    block.*.size -= lastChunk.size;

                    const empty = alloc.create(Block) catch unreachable;
                    empty.*.size = lastChunk.size;
                    empty.*.value = null;

                    disk.items[reversedI] = empty;
                    disk.insert(i, lastChunk) catch unreachable;
                }

                break;
            }
        }

        // printDisk(&disk);
    }

    var sum: u64 = 0;
    var i: usize = 0;
    for (disk.items) |block| {
        if (block.value) |blockId| {
            const loopEnd = i + block.size;
            while (i < loopEnd) : (i += 1) {
                sum += i * blockId;
            }
        } else {
            i += block.size;
        }
    }

    print("{}\n", .{sum});
}
