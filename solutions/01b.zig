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

fn readline() ![]u8 {
    const line = try stdin.takeDelimiter('\n');
    if (line == null) {
        return Test.Bad;
    }
    return line.?;
}

pub fn main() !void {
    var x: i16 = 50;
    var ans: i16 = 0;

    while (true) {
        const line = readline() catch {
            break;
        };

        const dir: i16 = if (line[0] == 'R') 1 else -1;
        var num: i16 = 0;

        for (line[1..]) |d| {
            num = num * 10 + (d - '0');
        }

        while (num > 0) {
            x = @rem(x + dir + 100, 100);
            if (x == 0) {
                ans += 1;
            }
            num -= 1;
        }

        try stdout.print("line: {}\n", .{num});
    }

    try stdout.print("ans: {}", .{ans});
    try stdout.flush();
}
