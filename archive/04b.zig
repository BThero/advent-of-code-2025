const std = @import("std");
const io = std.testing.io;
var stdin_buffer: [1024 * 1024]u8 = undefined;
var stdout_buffer: [1024 * 1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;

fn readline(delim: u8) ![]u8 {
    const line = try stdin.takeDelimiter(delim);
    if (line == null) {
        return error.EndOfStream;
    }
    return line.?;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var lines = try std.ArrayList([]u8).initCapacity(allocator, 0);

    while (true) {
        const line = readline('\n') catch {
            break;
        };
        try lines.append(allocator, line);
    }

    var ans: u32 = 0;
    const SignedIndex = i32;
    var try_more: bool = true;

    while (try_more) {
        try_more = false;
        for (0..lines.items.len) |_i| {
            for (0..lines.items[_i].len) |_j| {
                if (lines.items[_i][_j] != '@') {
                    continue;
                }

                const i: SignedIndex = @intCast(_i);
                const j: SignedIndex = @intCast(_j);
                var dx: SignedIndex = -1;
                var cnt: u64 = 0;
                while (dx <= 1) {
                    var dy: SignedIndex = -1;
                    while (dy <= 1) {
                        if (dx == 0 and dy == 0) {
                            dy += 1;
                            continue;
                        }
                        const ni: SignedIndex = i + dx;
                        const nj: SignedIndex = j + dy;
                        if (ni < 0 or nj < 0 or ni >= lines.items.len or nj >= lines.items[_i].len) {
                            dy += 1;
                            continue;
                        }
                        if (lines.items[@intCast(ni)][@intCast(nj)] == '@') {
                            cnt += 1;
                        }
                        dy += 1;
                    }
                    dx += 1;
                }

                if (cnt < 4) {
                    lines.items[_i][_j] = '.';
                    ans += 1;
                    try_more = true;
                }
            }
        }
    }

    try stdout.print("ans: {}\n", .{ans});
    try stdout.flush();
}
