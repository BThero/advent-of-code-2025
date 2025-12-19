const std = @import("std");
const io = std.testing.io;
var stdin_buffer: [1024 * 1024]u8 = undefined;
var stdout_buffer: [1024 * 1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;

const Point = [2]i64;

const UnwrapError = error{NoValue};
fn unwrap_or_error(T: type, x: ?T) !T {
    if (x == null) {
        return UnwrapError.NoValue;
    } else {
        return x.?;
    }
}

fn readline(delim: u8) ?[]u8 {
    const line = stdin.takeDelimiter(delim) catch {
        return null;
    };
    return line;
}

const Machine = struct {
    mask: u64,
    n: usize,
    buttons: []u64,
    joltage: []u64,
};

fn parse_mask(str: []u8) struct { u64, usize } {
    std.debug.assert(str[0] == '[');
    std.debug.assert(str[str.len - 1] == ']');
    const bits = str[1 .. str.len - 1];
    const n = bits.len;
    var mask: u64 = 0;
    for (0..n) |i| {
        if (bits[i] == '#') {
            const i_: u6 = @intCast(i);
            const one: u64 = 1;
            mask |= (one << i_);
        }
    }
    return .{ mask, n };
}

fn parse_joltage(str: []u8) ![]u64 {
    const allocator = std.heap.page_allocator;
    std.debug.assert(str[0] == '{');
    std.debug.assert(str[str.len - 1] == '}');
    var num: u64 = 0;
    var num_ct = try std.ArrayList(u64).initCapacity(allocator, 0);

    for (str[1 .. str.len - 1]) |ch| {
        if (ch == ',') {
            try num_ct.append(allocator, num);
            num = 0;
        } else {
            num = num * 10 + (ch - '0');
        }
    }

    try num_ct.append(allocator, num);
    return num_ct.items;
}

fn parse_button(str: []u8) u64 {
    std.debug.assert(str[0] == '(');
    std.debug.assert(str[str.len - 1] == ')');
    const one: u64 = 1;
    var button: u64 = 0;
    var num: u64 = 0;
    var num_: u6 = 0;

    for (str[1 .. str.len - 1]) |ch| {
        if (ch == ',') {
            num_ = @intCast(num);
            button |= (one << num_);
            num = 0;
        } else {
            num = num * 10 + (ch - '0');
        }
    }

    num_ = @intCast(num);
    button |= (one << num_);
    return button;
}

fn parse_buttons(str: []u8) ![]u64 {
    const allocator = std.heap.page_allocator;
    var button_ct = try std.ArrayList(u64).initCapacity(allocator, 0);
    var last_pos: usize = 0;

    for (0..str.len) |i| {
        const ch = str[i];
        if (ch == ' ') {
            try button_ct.append(allocator, parse_button(str[last_pos..i]));
            last_pos = i + 1;
        }
    }

    try button_ct.append(allocator, parse_button(str[last_pos..str.len]));
    return button_ct.items;
}

fn read_machine() ?Machine {
    const line = readline('\n') orelse {
        return null;
    };

    const first_ws = std.mem.find(u8, line, " ").?;
    const last_ws = std.mem.findLast(u8, line, " ").?;

    const mask_str = line[0..first_ws];
    const buttons_str = line[first_ws + 1 .. last_ws];
    const joltage_str = line[last_ws + 1 .. line.len];

    stdout.print("parts: {s} | {s} | {s}\n", .{ mask_str, buttons_str, joltage_str }) catch {};
    stdout.flush() catch {};

    const mask, const n = parse_mask(mask_str);
    const buttons = parse_buttons(buttons_str) catch {
        return null;
    };
    const joltage = parse_joltage(joltage_str) catch {
        return null;
    };

    return Machine{ .mask = mask, .n = n, .buttons = buttons, .joltage = joltage };
}

fn solve_machine(m: Machine) !(?u64) {
    const allocator = std.heap.page_allocator;
    var queue = try std.Deque(u64).initCapacity(allocator, 0);
    const one: u64 = 1;
    const n_: u6 = @intCast(m.n);
    const n: usize = (one << n_);
    const dist = try allocator.alloc(?u64, n);
    for (0..dist.len) |i| {
        dist[i] = null;
    }
    dist[0] = 0;
    try queue.pushBack(allocator, 0);

    while (queue.popFront()) |v| {
        for (m.buttons) |button| {
            const to = (v ^ button);
            if (dist[to] == null) {
                dist[to] = dist[v].? + 1;
                try queue.pushBack(allocator, to);
            }
        }
    }

    return dist[m.mask];
}

pub fn main() !void {
    var ans: u64 = 0;

    while (read_machine()) |machine| {
        ans += (try solve_machine(machine)).?;
    }

    try stdout.print("ans: {}\n", .{ans});
    try stdout.flush();
}
