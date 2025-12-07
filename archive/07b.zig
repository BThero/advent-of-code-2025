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

pub fn main() !void {
    const N = 1000;
    var table = try read_table();
    var dp: [N][N]u64 = .{.{0} ** N} ** N;

    for (0..table[0].len) |i| {
        if (table[0][i] == 'S') {
            dp[0][i] = 1;
        }
    }

    for (1..table.len) |i| {
        for (0..table[i].len) |j| {
            if (table[i][j] == '.') {
                dp[i][j] += dp[i - 1][j];
            } else if (table[i][j] == '^') {
                dp[i][j - 1] += dp[i - 1][j];
                dp[i][j + 1] += dp[i - 1][j];
            }
        }
    }

    var sum: u64 = 0;

    for (0..table[0].len) |i| {
        sum += dp[table.len - 1][i];
    }

    try stdout.print("{}\n", .{sum});
    try stdout.flush();
}
