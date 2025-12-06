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

fn read_table() ![][]u8 {
    const allocator = std.heap.page_allocator;
    var table_ct = try std.ArrayList([]u8).initCapacity(allocator, 0);

    while (readline('\n')) |line| {
        try table_ct.append(allocator, line);
    }

    return table_ct.items;
}

fn calc_expr(nums: []i64, op: u8) i64 {
    var res: i64 = undefined;

    if (op == '+') {
        res = 0;
        for (nums) |num| {
            res += num;
        }
    } else {
        res = 1;
        for (nums) |num| {
            res *= num;
        }
    }

    return res;
}

fn parse_column(col: []u8) struct { ?i64, ?u8 } {
    var num: ?i64 = null;
    var op: ?u8 = null;

    for (col) |ch| {
        if (ch >= '0' and ch <= '9') {
            if (num == null) {
                num = ch - '0';
            } else {
                num = num.? * 10 + (ch - '0');
            }
        } else if (ch == '+' or ch == '*') {
            op = ch;
        }
    }

    return .{ num, op };
}

pub fn main() !void {
    const table = try read_table();
    var sum: i64 = 0;

    const allocator = std.heap.page_allocator;
    var nums = try std.ArrayList(i64).initCapacity(allocator, 0);
    var j: usize = table[0].len;
    while (j > 0) {
        j -= 1;
        var col = try allocator.alloc(u8, table.len);

        for (0..table.len) |i| {
            col[i] = table[i][j];
        }

        const num_, const op_ = parse_column(col);

        if (num_) |num| {
            try nums.append(allocator, num);
        }

        if (op_) |op| {
            sum += calc_expr(nums.items, op);
            nums.clearAndFree(allocator);
        }
    }

    try stdout.print("{}\n", .{sum});
    try stdout.flush();
}
