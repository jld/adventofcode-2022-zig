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

    fn make_light(self: *const Self) !Light {
        const xdu = self.xdim;
        const ydu = self.ydim;
        const xdi = @intCast(isize, xdu);
        const ydi = @intCast(isize, ydu);

        var light = try Light.init(self.allocator, xdu, ydu);

        var y: isize = 0;
        while (y < ydi) : (y += 1) {
            light.raycast(self, self.coord(0, y), self.coord(1, 0), xdu);
            light.raycast(self, self.coord(xdi - 1, y), self.coord(-1, 0), xdu);
        }
        var x: isize = 0;
        while (x < xdi) : (x += 1) {
            light.raycast(self, self.coord(x, 0), self.coord(0, 1), ydu);
            light.raycast(self, self.coord(x, ydi - 1), self.coord(0, -1), ydu);
        }

        return light;
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

    fn raycast(self: *Self, trees: *const Trees, p0: isize, dp: isize, n: usize) void {
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

fn io_main(ctx: util.IOContext) !void {
    var tr = try Trees.parse(ctx.gpa, ctx.input);
    defer tr.deinit();
    try ctx.stdout.print("{}x{}\n", .{ tr.xdim, tr.ydim });

    var li = try tr.make_light();
    defer li.deinit();
    try ctx.stdout.print("{} lit\n", .{li.count()});
}

pub fn main() !void {
    try util.io_shell(io_main);
}
