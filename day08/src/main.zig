const std = @import("std");
const util = @import("aoc-util");
const Allocator = std.mem.Allocator;

const Trees = struct {
    const Self = @This();

    allocator: Allocator,
    hmap: []u8,
    xdim: usize,
    ydim: usize,

    fn init(a: Allocator) Self {
        return .{
            .allocator = a,
            .hmap = &[_]u8{},
            .xdim = 0,
            .ydim = 0,
        };
    }
    fn deinit(self: *Self) void {
        self.allocator.free(self.hmap);
    }

    fn parse(allocator: Allocator, input: []const u8) !Self {
        var self = init(allocator);
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();

        var lines = util.lines(input);
        const line0 = lines.first();
        self.xdim = line0.len;
        self.ydim = 1;
        try buf.appendSlice(line0);
        while (lines.next()) |line| {
            if (line.len != self.xdim) {
                return error.RaggedLines;
            }
            self.ydim += 1;
            try buf.appendSlice(line);
        }
        for (buf.items) |*byte| {
            if (byte.* < '0' or byte.* > '9') {
                return error.Overflow;
            }
            byte.* -= '0';
        }
        self.hmap = try buf.toOwnedSlice();
        return self;
    }

    fn coord(self: *const Self, x: isize, y: isize) isize {
        return y * @intCast(isize, self.xdim) + x;
    }

    fn make_thing(self: *const Self, comptime Thing: type) !Thing {
        const xdu = self.xdim;
        const ydu = self.ydim;
        const xdi = @intCast(isize, xdu);
        const ydi = @intCast(isize, ydu);

        var thing = try Thing.init(self.allocator, xdu, ydu);

        var y: isize = 0;
        while (y < ydi) : (y += 1) {
            thing.raycast(self, 0, self.coord(0, y), self.coord(1, 0), xdu);
            thing.raycast(self, 1, self.coord(xdi - 1, y), self.coord(-1, 0), xdu);
        }
        var x: isize = 0;
        while (x < xdi) : (x += 1) {
            thing.raycast(self, 2, self.coord(x, 0), self.coord(0, 1), ydu);
            thing.raycast(self, 3, self.coord(x, ydi - 1), self.coord(0, -1), ydu);
        }

        return thing;
    }

    fn make_light(self: *const Self) !Light {
        return self.make_thing(Light);
    }
    fn make_scenery(self: *const Self) !Scenery {
        return self.make_thing(Scenery);
    }
};

test "Trees/parse" {
    const t = std.testing;
    const example = @embedFile("example0.txt");

    var tr = try Trees.parse(t.allocator, example);
    defer tr.deinit();

    try t.expectEqual(@as(usize, 5), tr.xdim);
    try t.expectEqual(@as(usize, 5), tr.ydim);
    try t.expectEqual(@as(usize, 25), tr.hmap.len);
    try t.expectEqual(@as(u8, 7), tr.hmap[3]);
}

const Light = struct {
    const Self = @This();

    allocator: Allocator,
    lmap: []bool,

    fn raycast(self: *Self, trees: *const Trees, dir: usize, p0: isize, dp: isize, n: usize) void {
        _ = dir;
        var light: u8 = 0;
        var i: usize = 0;
        var p = p0;
        while (i < n and light < 10) : ({
            i += 1;
            p += dp;
        }) {
            const here = trees.hmap[@intCast(usize, p)];
            if (here >= light) {
                light = here + 1;
                self.lmap[@intCast(usize, p)] = true;
            }
        }
    }

    fn init(allocator: Allocator, xdim: usize, ydim: usize) !Self {
        const lmap = try allocator.alloc(bool, xdim * ydim);
        errdefer allocator.free(lmap);
        for (lmap) |*e| {
            e.* = false;
        }
        return Self{
            .allocator = allocator,
            .lmap = lmap,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.lmap);
    }

    fn count(self: *const Self) usize {
        var acc: usize = 0;
        for (self.lmap) |b| {
            if (b) {
                acc += 1;
            }
        }
        return acc;
    }
};

test "Light/square" {
    const t = std.testing;
    const example = @embedFile("example0.txt");

    var tr = try Trees.parse(t.allocator, example);
    defer tr.deinit();
    var li = try tr.make_light();
    defer li.deinit();

    try t.expectEqual(@as(usize, 21), li.count());
}

test "Light/rectangle" {
    const t = std.testing;
    // Intended to catch anywhere I mixed up x and y dimensions.
    const examples = .{
        \\30373
        \\25512
        \\65332
        ,
        \\303
        \\255
        \\653
        \\335
        \\353
    };

    inline for (examples) |example| {
        var tr = try Trees.parse(t.allocator, example);
        defer tr.deinit();
        var li = try tr.make_light();
        defer li.deinit();

        // Conveniently they both have the same answer.
        try t.expectEqual(@as(usize, 14), li.count());
    }
}

const Scenery = struct {
    const Self = @This();
    const View = [4]u8;

    allocator: Allocator,
    views: []View,

    fn init(allocator: Allocator, xdim: usize, ydim: usize) !Self {
        if (xdim > 255 or ydim > 255) {
            return error.TooBig;
        }
        const views = try allocator.alloc(View, xdim * ydim);
        return Self{
            .allocator = allocator,
            .views = views,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.views);
    }

    fn raycast(self: *Self, trees: *const Trees, dir: usize, p0: isize, dp: isize, n: usize) void {
        var rays = [_]u8{0} ** 10;

        var i: usize = 0;
        var p = p0;
        while (i < n) : ({
            i += 1;
            p += dp;
        }) {
            const pp = @intCast(usize, p);
            const here = @as(usize, trees.hmap[pp]);
            self.views[pp][dir] = rays[here];
            var j: usize = 0;
            while (j <= here) : (j += 1) {
                rays[j] = 1;
            }
            while (j < 10) : (j += 1) {
                rays[j] += 1;
            }
        }
    }

    fn score_at(self: *const Self, idx: usize) u32 {
        var acc: u32 = 1;
        for (self.views[idx]) |dv| {
            acc *= @as(u32, dv);
        }
        return acc;
    }

    fn max_score(self: *const Self) u32 {
        var best: u32 = 0;
        for (self.views) |_, i| {
            const here = self.score_at(i);
            if (best < here) {
                best = here;
            }
        }
        return best;
    }
};

test "scenery" {
    const t = std.testing;
    const example = @embedFile("example0.txt");

    var tr = try Trees.parse(t.allocator, example);
    defer tr.deinit();
    var sc = try tr.make_scenery();
    defer sc.deinit();

    try t.expectEqual(@as(u32, 4), sc.score_at(5 * 1 + 2));
    try t.expectEqual(@as(u32, 8), sc.score_at(5 * 3 + 2));
    try t.expectEqual(@as(u32, 8), sc.max_score());
}

fn io_main(ctx: util.IOContext) !void {
    var tr = try Trees.parse(ctx.gpa, ctx.input);
    defer tr.deinit();
    try ctx.stdout.print("{}x{}\n", .{ tr.xdim, tr.ydim });

    {
        var li = try tr.make_light();
        defer li.deinit();
        try ctx.stdout.print("{} lit\n", .{li.count()});
    }

    {
        var sc = try tr.make_scenery();
        defer sc.deinit();
        try ctx.stdout.print("{} scenery\n", .{sc.max_score()});
        if (false) {
            for (sc.views) |view, i| {
                // zig fmt: off
                try ctx.stdout.print(
                    "sc[{}] = {} {} {} {}\n",
                    .{ i, view[0], view[1], view[2], view[3] }
                );
                // zig fmt: on
            }
        }
    }
}

pub fn main() !void {
    try util.io_shell(io_main);
}
