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

fn has_digits(line: []u8) bool {
    for (line) |ch| {
        if (ch >= '0' and ch <= '9') {
            return true;
        }
    }
    return false;
}

fn parse_numbers(line: []u8) ![]i64 {
    const allocator = std.heap.page_allocator;
    var nums = try std.ArrayList(i64).initCapacity(allocator, 0);
    var curr_num: i64 = -1;

    for (line) |ch| {
        if (ch >= '0' and ch <= '9') {
            if (curr_num == -1) {
                curr_num = ch - '0';
            } else {
                curr_num = curr_num * 10 + (ch - '0');
            }
        } else if (curr_num != -1) {
            try nums.append(allocator, curr_num);
            curr_num = -1;
        }
    }

    if (curr_num != -1) {
        try nums.append(allocator, curr_num);
    }

    return nums.items;
}

fn parse_ops(line: []u8) ![]u8 {
    const allocator = std.heap.page_allocator;
    var ops = try std.ArrayList(u8).initCapacity(allocator, 0);

    for (line) |ch| {
        if (ch == '+' or ch == '*') {
            try ops.append(allocator, ch);
        }
    }

    return ops.items;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var rows = try std.ArrayList([]i64).initCapacity(allocator, 1024);
    var ops: []u8 = undefined;

    while (readline('\n')) |line| {
        if (has_digits(line)) {
            const row = try parse_numbers(line);
            try rows.append(allocator, row);
        } else {
            ops = try parse_ops(line);
        }
    }

    var sum: i64 = 0;

    for (0..ops.len) |j| {
        const op = ops[j];
        var res: i64 = undefined;

        if (op == '+') {
            res = 0;
            for (0..rows.items.len) |i| {
                res += rows.items[i][j];
            }
        } else {
            res = 1;
            for (0..rows.items.len) |i| {
                res *= rows.items[i][j];
            }
        }

        sum += res;
    }

    try stdout.print("{}\n", .{sum});
    try stdout.flush();
}
