const std = @import("std");
const io = std.testing.io;
var stdin_buffer: [1024 * 1024]u8 = undefined;
var stdout_buffer: [1024 * 1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;

fn readline(delim: u8) ?[]u8 {
    const line = stdin.takeDelimiter(delim) catch {
        return null;
    };
    return line;
}

const Segment = struct { left: u64, right: u64 };

fn lessThan(_: void, a: Segment, b: Segment) bool {
    return a.left < b.left or (a.left == b.left and a.right < b.right);
}

pub fn calc_num_of_covered_points(segments: []Segment) u64 {
    std.mem.sort(Segment, segments, {}, lessThan);
    var last_num: u64 = 0;
    var ans: u64 = 0;
    for (segments) |seg| {
        if (seg.right > last_num) {
            ans += seg.right + 1 - @max(last_num + 1, seg.left);
            last_num = seg.right;
        }
    }
    return ans;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var segments = try std.ArrayList(Segment).initCapacity(allocator, 1024);
    var is_reading_segments: bool = true;
    var ans: u64 = 0;

    while (readline('\n')) |line| {
        if (line.len == 0) {
            is_reading_segments = false;
            continue;
        }
        if (is_reading_segments) {
            const index = std.mem.find(u8, line, "-").?;
            const lhs = line[0..index];
            const rhs = line[(index + 1)..line.len];
            const L = try std.fmt.parseInt(u64, lhs, 10);
            const R = try std.fmt.parseInt(u64, rhs, 10);
            try segments.append(allocator, Segment{ .left = L, .right = R });
        } else {
            // nothing
        }
    }

    ans = calc_num_of_covered_points(segments.items);
    try stdout.print("ans: {}\n", .{ans});
    try stdout.flush();
}
