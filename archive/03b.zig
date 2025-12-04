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

fn get_best(line: []u8) u64 {
    const K = 12;

    var dp: [K]i64 = undefined;
    var pw10: [K]i64 = undefined;

    for (0..K) |i| {
        dp[i] = std.math.minInt(i64);
        if (i == 0) {
            pw10[i] = 1;
        } else {
            pw10[i] = pw10[i - 1] * 10;
        }
    }

    var i = line.len;
    while (i > 0) {
        i -= 1;

        var j: usize = K;
        const d: i64 = line[i] - '0';
        while (j > 0) {
            j -= 1;
            dp[j] = @max(dp[j], (if (j > 0) dp[j - 1] else 0) + d * pw10[j]);
        }
    }

    return @abs(dp[K - 1]);
}

pub fn main() !void {
    var sum: u64 = 0;

    while (true) {
        const line = readline('\n') catch {
            break;
        };

        const best = get_best(line);
        sum += get_best(line);
        try stdout.print("best: {}\n", .{best});
    }

    try stdout.print("sum: {}\n", .{sum});
    try stdout.flush();
}
