const std = @import("std");
const io = std.testing.io;
var stdin_buffer: [1024 * 1024]u8 = undefined;
var stdout_buffer: [1024 * 1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(io, &stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;

const Point = [3]i64;

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

fn read_point() !Point {
    var point: Point = undefined;
    for (0..3) |i| {
        const maybe_str = readline(if (i < 2) ',' else '\n');
        const str = try unwrap_or_error([]u8, maybe_str);
        const num = try std.fmt.parseInt(i64, str, 10);
        point[i] = num;
    }
    return point;
}

fn dist_squared(self: Point, other: Point) u64 {
    var res: u64 = 0;
    inline for (0..self.len) |i| {
        const d = @abs(self[i] - other[i]);
        res += d * d;
    }
    return res;
}

const Line = struct {
    a: usize,
    b: usize,
    dist: u64,
};

fn less_than(_: void, a: Line, b: Line) bool {
    return a.dist < b.dist;
}

const DisjointSetUnion = struct {
    parent: []usize,
    size: []usize,

    pub fn init(gpa: std.mem.Allocator, n: usize) !DisjointSetUnion {
        const parent = try gpa.alloc(usize, n);
        const size = try gpa.alloc(usize, n);

        for (0..n) |i| {
            parent[i] = i;
            size[i] = 1;
        }

        return DisjointSetUnion{ .parent = parent, .size = size };
    }

    fn get_root(self: DisjointSetUnion, v: usize) usize {
        if (self.parent[v] == v) {
            return v;
        } else {
            self.parent[v] = get_root(self, self.parent[v]);
            return self.parent[v];
        }
    }

    pub fn try_connect(self: DisjointSetUnion, a: usize, b: usize) bool {
        const root_a = get_root(self, a);
        const root_b = get_root(self, b);

        if (root_a == root_b) {
            return false;
        }

        self.parent[root_a] = root_b;
        self.size[root_b] += self.size[root_a];
        return true;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var points_ct = try std.ArrayList(Point).initCapacity(allocator, 0);
    while (read_point()) |point| {
        try points_ct.append(allocator, point);
    } else |_| {}
    const points = points_ct.items;
    const n = points.len;

    var lines_ct = try std.ArrayList(Line).initCapacity(allocator, n * n);
    for (0..n) |i| {
        for (i + 1..n) |j| {
            try lines_ct.append(allocator, Line{ .a = i, .b = j, .dist = dist_squared(points[i], points[j]) });
        }
    }
    const lines = lines_ct.items;
    std.mem.sort(Line, lines, {}, less_than);

    const dsu = try DisjointSetUnion.init(allocator, n);
    for (lines) |line| {
        const conn = dsu.try_connect(line.a, line.b);
        if (conn) {
            const p = points[line.a];
            const q = points[line.b];
            try stdout.print("{} * {} = {}\n", .{ p[0], q[0], p[0] * q[0] });
        }
    }

    try stdout.flush();
}
