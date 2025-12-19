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
    var table = try read_table();
    var split_count: u32 = 0;

    for (1..table.len) |i| {
        for (0..table[i].len) |j| {
            const ch_upper = table[i - 1][j];

            if (ch_upper == 'S') {
                if (table[i][j] == '.') {
                    table[i][j] = 'S';
                } else if (table[i][j] == '^') {
                    split_count += 1;
                    table[i][j - 1] = 'S';
                    table[i][j + 1] = 'S';
                }
            }
        }
    }

    try stdout.print("{}\n", .{split_count});
    try stdout.flush();
}
