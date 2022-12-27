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

const Rope1 = struct {
    const Self = @This();
    head: Pos,
    tail: Move,

    fn init() Self {
        return .{ .head = Pos.zero, .tail = Move.zero };
    }

    fn move(self: *Self, mov0: Move) void {
        self.head = self.head.add(mov0);
        self.tail = self.tail.sub(mov0);
        _ = self.tail.contract();
    }

    fn tail_pos(self: *const Self) Pos {
        return self.head.add(self.tail);
    }
};

test "rope example" {
    const t = std.testing;
    
    var r = Rope1.init();
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

fn io_main(ctx: util.IOContext) !void {
    _ = ctx;
}

pub fn main() !void {
    try util.io_shell(io_main);
}
