const std = @import("std");
const util = @import("aoc-util");

const Move = struct {
    dx: i8,
    dy: i8,

    fn init(dx: i8, dy: i8) Move {
        return .{ .dx = dx, .dy = dy };
    }
    const zero = init(0, 0);
    const left = init(-1, 0);
    const right = init(1, 0);
    const up = init(0, -1);
    const down = init(0, 1);

    fn add(self: Move, other: Move) Move {
        return init(self.dx + other.dx, self.dy + other.dy);
    }
    fn sub(self: Move, other: Move) Move {
        return init(self.dx - other.dx, self.dy - other.dy);
    }

    fn touching(self: Move) bool {
        return self.dx >= -1 and self.dx <= 1 and self.dy >= -1 and self.dy <= 1;
    }

    fn contract(self: *Move) Move {
        var rv = zero;
        if (!self.touching()) {
            if (self.dx < 0) {
                self.dx += 1;
                rv.dx -= 1;
            } else if (self.dx > 0) {
                self.dx -= 1;
                rv.dx += 1;
            }
            if (self.dy < 0) {
                self.dy += 1;
                rv.dy -= 1;
            } else if (self.dy > 0) {
                self.dy -= 1;
                rv.dy += 1;
            }
        }
        return rv;
    }

    fn eql(self: Move, other: Move) bool {
        return self.dx == other.dx and self.dy == other.dy;
    }
};

test "touching" {
    const t = std.testing;

    try t.expect(Move.zero.touching());
    try t.expect(Move.left.touching());
    try t.expect(Move.down.touching());
    try t.expect(Move.up.add(Move.right).touching());
    try t.expect(!Move.left.sub(Move.right).touching());
}

test "contract" {
    const t = std.testing;
    const zero = Move.zero;
    const left = Move.left;
    const right = Move.right;
    const up = Move.up;
    const down = Move.down;

    const ortho = .{ left, right, up, down };
    const diag = .{ left.add(up), left.add(down), right.add(up), right.add(down) };
    const oriented = .{
        .{ left, up },
        .{ left, down },
        .{ right, up },
        .{ right, down },
        .{ up, left },
        .{ up, right },
        .{ down, left },
        .{ down, right },
    };

    // Zero is fine.
    {
        var m = zero;
        try t.expect(m.contract().eql(zero));
        try t.expect(m.eql(zero));
    }

    // UDLR is fine.
    inline for (ortho) |dir| {
        var m = dir;
        try t.expect(m.contract().eql(zero));
        try t.expect(m.eql(dir));
    }

    // Diagonal is fine.
    inline for (diag) |dir| {
        var m = dir;
        try t.expect(m.contract().eql(zero));
        try t.expect(m.eql(dir));
    }

    // 2xUDLR moves that way.
    inline for (ortho) |dir| {
        var m = dir.add(dir);
        try t.expect(m.contract().eql(dir));
        try t.expect(m.eql(dir));
    }

    // Double diagonal does the obvious thing.
    // (Not explicitly specified… yet.)
    inline for (diag) |dir| {
        var m = dir.add(dir);
        try t.expect(m.contract().eql(dir));
        try t.expect(m.eql(dir));
    }

    // Knight move gets rid of the diagonal.
    inline for (oriented) |case| {
        const dort = case[0];
        const ddia = case[0].add(case[1]);
        var m = dort.add(ddia);
        try t.expect(m.contract().eql(ddia));
        try t.expect(m.eql(dort));
    }
}

const coord_t = i32;
const Pos = struct {
    x: coord_t,
    y: coord_t,

    fn init(x: coord_t, y: coord_t) Pos {
        return .{ .x = x, .y = y };
    }
    const zero = init(0, 0);

    fn add(self: Pos, delta: Move) Pos {
        return init(self.x + @as(coord_t, delta.dx), self.y + @as(coord_t, delta.dy));
    }
    fn is_at(self: Pos, ex: coord_t, ey: coord_t) bool {
        return self.x == ex and self.y == ey;
    }
};

fn Rope(comptime len: usize) type {
    return struct {
        const Self = @This();
        head: Pos,
        tail: [len]Move,

        fn init() Self {
            return .{ .head = Pos.zero, .tail = [_]Move{Move.zero} ** len };
        }

        fn move(self: *Self, mov0: Move) void {
            self.head = self.head.add(mov0);
            var mov = mov0;
            for (self.tail) |*seg| {
                seg.* = seg.sub(mov);
                mov = seg.contract();
            }
        }

        fn tail_pos(self: *const Self) Pos {
            var pos = self.head;
            for (self.tail) |seg| {
                pos = pos.add(seg);
            }
            return pos;
        }
    };
}

test "rope example" {
    const t = std.testing;

    var r = Rope(1).init();
    r.move(Move.right);
    try t.expect(r.head.is_at(1, 0));
    try t.expect(r.tail_pos().is_at(0, 0));
    r.move(Move.right);
    try t.expect(r.head.is_at(2, 0));
    try t.expect(r.tail_pos().is_at(1, 0));
    r.move(Move.right);
    r.move(Move.right);
    try t.expect(r.head.is_at(4, 0));
    try t.expect(r.tail_pos().is_at(3, 0));
    r.move(Move.up);
    try t.expect(r.head.is_at(4, -1));
    try t.expect(r.tail_pos().is_at(3, 0));
    r.move(Move.up);
    try t.expect(r.head.is_at(4, -2));
    try t.expect(r.tail_pos().is_at(4, -1));
    // That's probably enough.
}

const Tracer = struct {
    const Self = @This();
    const Trace = std.hash_map.AutoHashMap(Pos, void);
    trace: Trace,
    rope: Rope(1),

    fn init(a: std.mem.Allocator) !Self {
        var self = Self{ .trace = Trace.init(a), .rope = Rope(1).init() };
        try self.mark(Pos.zero);
        return self;
    }
    fn deinit(self: *Self) void {
        self.trace.deinit();
    }
    fn mark(self: *Self, point: Pos) !void {
        try self.trace.put(point, {});
    }
    fn count(self: *const Self) usize {
        return self.trace.count();
    }

    fn move(self: *Self, mov: Move) !void {
        self.rope.move(mov);
        try self.mark(self.rope.tail_pos());
    }
    fn move_n(self: *Self, mov: Move, n: usize) !void {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            try self.move(mov);
        }
    }

    fn apply_text(self: *Self, input: []const u8) !void {
        var lines = util.lines(input);
        while (lines.next()) |line| {
            const cmd = try Cmd.parse(line);
            try self.move_n(cmd.dir, cmd.amt);
        }
    }
};

test "example visited" {
    const t = std.testing;
    var tr = try Tracer.init(t.allocator);
    defer tr.deinit();

    try tr.move_n(Move.right, 4);
    try tr.move_n(Move.up, 4);
    try tr.move_n(Move.left, 3);
    try tr.move_n(Move.down, 1);
    try tr.move_n(Move.right, 4);
    try tr.move_n(Move.down, 1);
    try tr.move_n(Move.left, 5);
    try tr.move_n(Move.right, 2);

    try t.expect(tr.rope.head.is_at(2, -2));
    try t.expect(tr.rope.tail_pos().is_at(1, -2));

    try t.expectEqual(@as(usize, 13), tr.count());
}

const Cmd = struct {
    dir: Move,
    amt: usize,

    fn parse(input: []const u8) !Cmd {
        if (input.len < 3) {
            return error.TooShort;
        }
        if (input[1] != ' ') {
            return error.BadSyntax;
        }
        const dir = switch (input[0]) {
            'U' => Move.up,
            'D' => Move.down,
            'L' => Move.left,
            'R' => Move.right,
            else => return error.BadDirection,
        };
        return .{
            .dir = dir,
            .amt = try std.fmt.parseUnsigned(usize, input[2..], 10),
        };
    }
};

test "example, parsed" {
    const t = std.testing;
    const example = @embedFile("example0.txt");

    var tr = try Tracer.init(t.allocator);
    defer tr.deinit();

    try tr.apply_text(example);

    try t.expect(tr.rope.head.is_at(2, -2));
    try t.expect(tr.rope.tail_pos().is_at(1, -2));
    try t.expectEqual(@as(usize, 13), tr.count());
}

fn io_main(ctx: util.IOContext) !void {
    var tr = try Tracer.init(ctx.gpa);
    defer tr.deinit();
    try tr.apply_text(ctx.input);
    try ctx.stdout.print("{}\n", .{tr.count()});
}

pub fn main() !void {
    try util.io_shell(io_main);
}
