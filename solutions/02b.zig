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

fn digit_count(init_num: u64) u8 {
    var res: u8 = 0;
    var num = init_num;
    if (num == 0) {
        res = 1;
    }
    while (num > 0) {
        res += 1;
        num /= 10;
    }
    return res;
}

fn int_pow(base: u64, init_exp: u64) u64 {
    var res: u64 = 1;
    var exp = init_exp;
    while (exp > 0) {
        res *= base;
        exp -= 1;
    }
    return res;
}

fn is_invalid_id(x: u64) bool {
    const k = digit_count(x);

    for (1..k) |rep| {
        if (k % rep != 0) {
            continue;
        }
        var coef: u64 = 0;
        var exp: usize = 0;
        while (exp < k) {
            coef += int_pow(10, exp);
            exp += rep;
        }
        if (x % coef == 0) {
            return true;
        }
    }

    return false;
}

pub fn main() !void {
    var sum: u64 = 0;

    while (true) {
        const line = readline(',') catch {
            break;
        };

        const index = std.mem.find(u8, line, "-").?;
        const lhs = line[0..index];
        const rhs = line[index + 1 ..];

        const L = try std.fmt.parseInt(u64, lhs, 10);
        const R = try std.fmt.parseInt(u64, rhs, 10);

        for (L..R + 1) |num| {
            if (is_invalid_id(num)) {
                sum += num;
            }
        }

        try stdout.print("{s}, sum: {}\n", .{ line, sum });
    }

    try stdout.print("sum: {}\n", .{sum});
    try stdout.flush();
}
