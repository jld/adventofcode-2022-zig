const std = @import("std");

const Shape = enum(u3) {
    rock,
    paper,
    scissors,

    fn parse(comptime key: *const [3]u8, c: u8) !Shape {
        return switch (c) {
            key[0] => .rock,
            key[1] => .paper,
            key[2] => .scissors,
            else => error.BadCharacter,
        };
    }
};

test "parse_shape_abc" {
    const t = std.testing;
    try t.expectEqual(Shape.rock, try Shape.parse("ABC", 'A'));
    try t.expectEqual(Shape.paper, try Shape.parse("ABC", 'B'));
    try t.expectEqual(Shape.scissors, try Shape.parse("ABC", 'C'));
    try t.expectError(error.BadCharacter, Shape.parse("ABC", 'X'));
}

test "parse_shape_xyz" {
    const t = std.testing;
    try t.expectEqual(Shape.rock, try Shape.parse("XYZ", 'X'));
    try t.expectEqual(Shape.paper, try Shape.parse("XYZ", 'Y'));
    try t.expectEqual(Shape.scissors, try Shape.parse("XYZ", 'Z'));
    try t.expectError(error.BadCharacter, Shape.parse("XYZ", 'A'));
}

const End = enum(u3) {
    lose,
    draw,
    win,

    fn parse(comptime key: *const [3]u8, c: u8) !End {
        return switch (c) {
            key[0] => .lose,
            key[1] => .draw,
            key[2] => .win,
            else => error.BadCharacter,
        };
    }
};

test "parse_end_xyz" {
    const t = std.testing;
    try t.expectEqual(End.lose, try End.parse("XYZ", 'X'));
    try t.expectEqual(End.draw, try End.parse("XYZ", 'Y'));
    try t.expectEqual(End.win, try End.parse("XYZ", 'Z'));
    try t.expectError(error.BadCharacter, End.parse("XYZ", 'A'));
}

fn match_fwd(me: Shape, them: Shape) End {
    return @intToEnum(End, (@enumToInt(me) + 4 - @enumToInt(them)) % 3);
}

fn match_rev(them: Shape, end: End) Shape {
    return @intToEnum(Shape, (@enumToInt(them) + 2 + @enumToInt(end)) % 3);
}

const validation = .{
    .{ Shape.rock, Shape.rock, End.draw },
    .{ Shape.paper, Shape.paper, End.draw },
    .{ Shape.scissors, Shape.scissors, End.draw },
    .{ Shape.rock, Shape.scissors, End.win },
    .{ Shape.scissors, Shape.paper, End.win },
    .{ Shape.paper, Shape.rock, End.win },
    .{ Shape.scissors, Shape.rock, End.lose },
    .{ Shape.paper, Shape.scissors, End.lose },
    .{ Shape.rock, Shape.paper, End.lose },
};

test "match_fwd" {
    const t = std.testing;
    inline for (validation) |testcase| {
        try t.expectEqual(testcase[2], match_fwd(testcase[0], testcase[1]));
    }
}

test "match_rev" {
    const t = std.testing;
    inline for (validation) |testcase| {
        try t.expectEqual(testcase[0], match_rev(testcase[1], testcase[2]));
    }
}

const score_t = i64;

fn score_round(them: Shape, me: Shape) score_t {
    return 1 + @enumToInt(me) + @as(score_t, 3) * @enumToInt(match_fwd(me, them));
}

test "score_round" {
    const t = std.testing;

    try t.expectEqual(@as(score_t, 8), score_round(.rock, .paper));
    try t.expectEqual(@as(score_t, 1), score_round(.paper, .rock));
    try t.expectEqual(@as(score_t, 6), score_round(.scissors, .scissors));

    try t.expectEqual(@as(score_t, 4), score_round(.rock, .rock));
    try t.expectEqual(@as(score_t, 7), score_round(.scissors, .rock));
}

fn GuideLine(comptime TR: type) type {
    return struct {
        const This = @This();

        lhs: Shape,
        rhs: TR,

        fn parse(input: []const u8) !This {
            if (input.len != 3) {
                return error.BadSyntax;
            }
            if (input[1] != ' ') {
                return error.BadSyntax;
            }
            return This{
                .lhs = try Shape.parse("ABC", input[0]),
                .rhs = try TR.parse("XYZ", input[2]),
            };
        }
    };
}

test "parse_line_p1" {
    const t = std.testing;
    const check = struct {
        fn call(input: []const u8, lhs: Shape, rhs: Shape) !void {
            const gl = try GuideLine(Shape).parse(input);
            try t.expectEqual(lhs, gl.lhs);
            try t.expectEqual(rhs, gl.rhs);
        }
    }.call;

    try check("A Y", .rock, .paper);
    try check("B X", .paper, .rock);
    try check("C Z", .scissors, .scissors);
}

test "parse_line_p2" {
    const t = std.testing;
    const check = struct {
        fn call(input: []const u8, lhs: Shape, rhs: End) !void {
            const gl = try GuideLine(End).parse(input);
            try t.expectEqual(lhs, gl.lhs);
            try t.expectEqual(rhs, gl.rhs);
        }
    }.call;

    try check("A Y", .rock, .draw);
    try check("B X", .paper, .lose);
    try check("C Z", .scissors, .win);
}

fn rscore_p1(gl: GuideLine(Shape)) score_t {
    return score_round(gl.lhs, gl.rhs);
}

fn rscore_p2(gl: GuideLine(End)) score_t {
    return score_round(gl.lhs, match_rev(gl.lhs, gl.rhs));
}

test "rscore_p1" {
    const t = std.testing;

    try t.expectEqual(@as(score_t, 8), rscore_p1(try GuideLine(Shape).parse("A Y")));
    try t.expectEqual(@as(score_t, 1), rscore_p1(try GuideLine(Shape).parse("B X")));
    try t.expectEqual(@as(score_t, 6), rscore_p1(try GuideLine(Shape).parse("C Z")));
}

test "rscore_p2" {
    const t = std.testing;

    try t.expectEqual(@as(score_t, 4), rscore_p2(try GuideLine(End).parse("A Y")));
    try t.expectEqual(@as(score_t, 1), rscore_p2(try GuideLine(End).parse("B X")));
    try t.expectEqual(@as(score_t, 7), rscore_p2(try GuideLine(End).parse("C Z")));
}

fn score(comptime Line: type, comptime rscore_fn: anytype, input: []const u8) !score_t {
    var lines = std.mem.split(u8, std.mem.trimRight(u8, input, "\n"), "\n");

    var acc: score_t = 0;
    while (lines.next()) |line| {
        var gl: Line = try Line.parse(line);
        acc += rscore_fn(gl);
    }
    return acc;
}

fn score_p1(input: []const u8) !score_t {
    return score(GuideLine(Shape), rscore_p1, input);
}

fn score_p2(input: []const u8) !score_t {
    return score(GuideLine(End), rscore_p2, input);
}

test "score_p1" {
    const t = std.testing;
    const example =
        \\A Y
        \\B X
        \\C Z
    ;
    try t.expectEqual(@as(score_t, 15), try score_p1(example));
}

test "score_p2" {
    const t = std.testing;
    const example =
        \\A Y
        \\B X
        \\C Z
    ;
    try t.expectEqual(@as(score_t, 12), try score_p2(example));
}

pub fn main() !void {}
