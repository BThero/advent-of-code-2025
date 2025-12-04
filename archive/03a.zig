const std = @import("std");
const io = std.testing.io;
var stdin_buffer: [1024 * 1024]u8 = undefined;
var stdout_buffer: [1024 * 1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;

const Test = error{
    Bad,
};

fn readline(delim: u8) ![]u8 {
    const line = try stdin.takeDelimiter(delim);
    if (line == null) {
        return Test.Bad;
    }
    return line.?;
}

fn get_best(line: []u8) u64 {
    var res: u64 = 0;

    for (0..line.len) |i| {
        for (i + 1..line.len) |j| {
            res = @max(res, (line[i] - 48) * 10 + (line[j] - 48));
        }
    }

    return res;
}

pub fn main() !void {
    var sum: u64 = 0;

    while (true) {
        const line = readline('\n') catch {
            break;
        };

        sum += get_best(line);
    }

    try stdout.print("sum: {}\n", .{sum});
    try stdout.flush();
}
