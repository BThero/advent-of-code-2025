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

const Point = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn dist_squared(self: Point, other: Point) u64 {
        const dx = @abs(self.x - other.x);
        const dy = @abs(self.y - other.y);
        const dz = @abs(self.z - other.z);
        return dx * dx + dy * dy + dz * dz;
    }
};

fn read_point() ?Point {
    const maybeX = readline(',');
    const maybeY = readline(',');
    const maybeZ = readline('\n');

    if (maybeX == null or maybeY == null or maybeZ == null) {
        return null;
    }

    const x = std.fmt.parseInt(i64, maybeX.?, 10) catch {
        return null;
    };
    const y = std.fmt.parseInt(i64, maybeY.?, 10) catch {
        return null;
    };
    const z = std.fmt.parseInt(i64, maybeZ.?, 10) catch {
        return null;
    };

    return Point{ .x = x, .y = y, .z = z };
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

    pub fn gather_sizes(self: DisjointSetUnion, gpa: std.mem.Allocator) ![]usize {
        const n = self.parent.len;
        var sizes = try std.ArrayList(usize).initCapacity(gpa, n);
        for (0..n) |i| {
            if (self.parent[i] == i) {
                try sizes.append(gpa, self.size[i]);
            }
        }
        return sizes.items;
    }
};

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    var points_ct = try std.ArrayList(Point).initCapacity(alloc, 0);

    while (read_point()) |point| {
        try points_ct.append(alloc, point);
    }

    const points = points_ct.items;
    const n = points.len;

    var lines_ct = try std.ArrayList(Line).initCapacity(alloc, n * n);

    for (0..n) |i| {
        for (i + 1..n) |j| {
            try lines_ct.append(alloc, Line{ .a = i, .b = j, .dist = points[i].dist_squared(points[j]) });
        }
    }

    const lines = lines_ct.items;
    std.mem.sort(Line, lines, {}, less_than);

    const dsu = try DisjointSetUnion.init(alloc, n);

    for (lines) |line| {
        const conn = dsu.try_connect(line.a, line.b);
        if (conn) {
            const p = points[line.a];
            const q = points[line.b];
            try stdout.print("{} * {} = {}\n", .{ p.x, q.x, p.x * q.x });
        }
    }

    try stdout.flush();
}
