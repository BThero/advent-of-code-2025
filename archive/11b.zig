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

const Graph = struct {
    dict: std.HashMap([]const u8, usize, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    adj_list: std.array_list.Aligned(std.array_list.Aligned(usize, null), null),

    fn get_id(self: *Graph, str: []const u8) !usize {
        const allocator = std.heap.page_allocator;

        if (self.dict.contains(str)) {
            return self.dict.get(str).?;
        } else {
            const new_id = self.adj_list.items.len;
            const new_list = try std.ArrayList(usize).initCapacity(allocator, 0);
            try self.dict.put(str, new_id);
            try self.adj_list.append(allocator, new_list);
            return new_id;
        }
    }
};

fn process_line(graph: *Graph) !bool {
    const allocator = std.heap.page_allocator;
    const v_str = readline(':') orelse {
        return false;
    };
    const nodes_str = readline('\n') orelse {
        return false;
    };

    const v = try graph.get_id(v_str);
    var idx: usize = 1;
    for (1..nodes_str.len) |i| {
        const ch = nodes_str[i];
        if (ch == ' ') {
            const to_str = nodes_str[idx..i];
            const to = try graph.get_id(to_str);
            try graph.adj_list.items[v].append(allocator, to);
            idx = i + 1;
        }
    }

    const to_str = nodes_str[idx..nodes_str.len];
    const to = try graph.get_id(to_str);
    try graph.adj_list.items[v].append(allocator, to);
    return true;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var graph = Graph{ .dict = std.StringHashMap(usize).init(allocator), .adj_list = try std.ArrayList(std.array_list.Aligned(usize, null)).initCapacity(allocator, 0) };

    while (process_line(&graph)) |b| {
        if (!b) {
            break;
        }
    } else |_| {}

    const start_node = try graph.get_id("svr");
    const end_node = try graph.get_id("out");
    const vis0 = try graph.get_id("dac");
    const vis1 = try graph.get_id("fft");

    const n = graph.adj_list.items.len;
    const dp = try allocator.alloc([4]u64, n);
    const new_dp = try allocator.alloc([4]u64, n);

    for (0..n) |i| {
        for (0..4) |j| {
            dp[i][j] = 0;
        }
    }

    dp[start_node][0] = 1;
    var ans: u64 = 0;

    for (0..2000) |_| {
        for (0..n) |i| {
            for (0..4) |j| {
                new_dp[i][j] = 0;
            }
        }

        for (0..n) |v| {
            for (0..4) |m| {
                for (graph.adj_list.items[v].items) |to| {
                    var new_m = m;
                    if (to == vis0) {
                        new_m |= 1;
                    }
                    if (to == vis1) {
                        new_m |= 2;
                    }
                    new_dp[to][new_m] += dp[v][m];
                }
            }
        }

        ans += new_dp[end_node][3];

        for (0..n) |v| {
            for (0..4) |j| {
                dp[v][j] = new_dp[v][j];
            }
        }
    }

    try stdout.print("{}\n", .{ans});
    try stdout.flush();
}
