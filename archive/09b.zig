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

fn read_point() !Point {
    const N = @typeInfo(Point).array.len;
    var point: Point = undefined;
    for (0..N) |i| {
        const maybe_str = readline(if (i < N - 1) ',' else '\n');
        const str = try unwrap_or_error([]u8, maybe_str);
        const num = try std.fmt.parseInt(i64, str, 10);
        point[i] = num;
    }
    return point;
}

fn get_pos(l: i64, r: i64, x: i64) u8 {
    if (x < l or x > r) {
        return 0;
    }
    if (l < x and x < r) {
        return 2;
    }
    return 1;
}

fn get_sign(x: i64) i64 {
    if (x == 0) {
        return 0;
    }
    return if (x < 0) -1 else 1;
}

// fn is_strictly_inside(a: Point, b: Point, p: Point) bool {
//     const min_x = @min(a[0], b[0]);
//     const max_x = @max(a[0], b[0]);
//     const min_y = @min(a[1], b[1]);
//     const max_y = @max(a[1], b[1]);
//     return min_x < p[0] and p[0] < max_x and min_y < p[1] and p[1] < max_y;
// }

fn isect_len(l0_: i64, r0_: i64, l1_: i64, r1_: i64) i64 {
    const l0 = @min(l0_, r0_);
    const r0 = @max(l0_, r0_);
    const l1 = @min(l1_, r1_);
    const r1 = @max(l1_, r1_);
    const l = @max(l0, l1);
    const r = @min(r0, r1);
    return if (l <= r) r - l + 1 else 0;
}

fn is_strictly_inside(ra: Point, rb: Point, la: Point, lb: Point) bool {
    const min_x = @min(ra[0], rb[0]) + 1;
    const max_x = @max(ra[0], rb[0]) - 1;
    const min_y = @min(ra[1], rb[1]) + 1;
    const max_y = @max(ra[1], rb[1]) - 1;

    if (min_x > max_x or min_y > max_y) {
        return false;
    }

    const p = isect_len(la[0], lb[0], min_x, max_x);
    const q = isect_len(la[1], lb[1], min_y, max_y);
    return p > 0 and q > 0;
}

fn isect(pts: []Point, a: Point, b: Point) bool {
    for (0..pts.len) |i| {
        const cur = pts[i];
        const nxt = pts[(i + 1) % pts.len];
        // const dx = get_sign(nxt[0] - cur[0]);
        // const dy = get_sign(nxt[1] - cur[1]);
        // const steps = if (dx != 0) @divExact(nxt[0] - cur[0], dx) else @divExact(nxt[1] - cur[1], dy);

        if (is_strictly_inside(a, b, cur, nxt)) {
            return true;
        }

        // for (0..10) |j_| {
        //     if (j_ <= steps) {
        //         const j: i64 = @intCast(j_);
        //         const p0 = Point{ cur[0] + dx * j, cur[1] + dy * j };
        //         const p1 = Point{ nxt[0] - dx * j, nxt[1] - dy * j };

        //         if (is_strictly_inside(a, b, p0) or is_strictly_inside(a, b, p1)) {
        //             return true;
        //         }
        //     }
        // }
    }

    return false;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var points_ct = try std.ArrayList(Point).initCapacity(allocator, 0);
    while (read_point()) |point| {
        try points_ct.append(allocator, point);
    } else |_| {}

    const n = points_ct.items.len;
    const points = points_ct.items;
    // const points = try allocator.alloc(Point, n);
    // for (0..n) |i| {
    //     points[i] = points_ct.items[i];
    //     points[i + n] = points_ct.items[i];
    // }

    var res: u64 = 0;

    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dx = @abs(points[i][0] - points[j][0]);
            const dy = @abs(points[i][1] - points[j][1]);
            const area = (dx + 1) * (dy + 1);

            if (!isect(points, points[i], points[j])) {
                res = @max(res, area);
            }
        }
    }

    try stdout.print("{}\n", .{res});
    try stdout.flush();
}
