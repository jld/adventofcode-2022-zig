const std = @import("std");

const Shape = enum { rock, paper, scissors };

fn parse_shape(comptime key: *const [3]u8, c: u8) !Shape {
    return switch (c) {
        key[0] => .rock,
        key[1] => .paper,
        key[2] => .scissors,
        else => error.BadCharacter,
    };
}

test "parse_abc" {
    const t = std.testing;
    try t.expectEqual(Shape.rock, try parse_shape("ABC", 'A'));
    try t.expectEqual(Shape.paper, try parse_shape("ABC", 'B'));
    try t.expectEqual(Shape.scissors, try parse_shape("ABC", 'C'));
    try t.expectError(error.BadCharacter, parse_shape("ABC", 'X'));
}

test "parse_xyz" {
    const t = std.testing;
    try t.expectEqual(Shape.rock, try parse_shape("XYZ", 'X'));
    try t.expectEqual(Shape.paper, try parse_shape("XYZ", 'Y'));
    try t.expectEqual(Shape.scissors, try parse_shape("XYZ", 'Z'));
    try t.expectError(error.BadCharacter, parse_shape("XYZ", 'A'));
}

const score_t = i64;

const Round = struct {
    them: Shape,
    me: Shape,

    fn won(self: Round) bool {
        const wins = [_]Round{
            .{ .me = .rock, .them = .scissors },
            .{ .me = .scissors, .them = .paper },
            .{ .me = .paper, .them = .rock },
        };
        inline for (wins) |win| {
            if (std.meta.eql(self, win)) {
                return true;
            }
        }
        return false;
    }

    fn swap(self: Round) Round {
        return .{ .them = self.me, .me = self.them };
    }

    fn lost(self: Round) bool {
        return self.swap().won();
    }

    fn score(self: Round) score_t {
        const tiebreaker: score_t = switch (self.me) {
            .rock => 1,
            .paper => 2,
            .scissors => 3,
        };
        const outcome: score_t = if (self.won()) 6 else if (self.lost()) 0 else 3;
        return outcome + tiebreaker;
    }
};

test "round_score" {
    const t = std.testing;
    try t.expectEqual(@as(score_t, 8), (Round{ .them = .rock, .me = .paper }).score());
    try t.expectEqual(@as(score_t, 1), (Round{ .them = .paper, .me = .rock }).score());
    try t.expectEqual(@as(score_t, 6), (Round{ .them = .scissors, .me = .scissors }).score());
}

fn parse_round(input: []const u8) !Round {
    if (input.len != 3) {
        return error.BadSyntax;
    }
    if (input[1] != ' ') {
        return error.BadSyntax;
    }
    return .{
        .them = try parse_shape("ABC", input[0]),
        .me = try parse_shape("XYZ", input[2]),
    };
}

test "parse_round" {
    const t = std.testing;
    const validate = struct { // lolsigh
        fn call(input: []const u8, exp_them: Shape, exp_me: Shape) !void {
            const round = try parse_round(input);
            try t.expectEqual(exp_them, round.them);
            try t.expectEqual(exp_me, round.me);
        }
    }.call;

    try validate("A Y", .rock, .paper);
    try validate("B X", .paper, .rock);
    try validate("C Z", .scissors, .scissors);
}

fn score_game(input: []const u8) !score_t {
    var lines = std.mem.split(u8, std.mem.trimRight(u8, input, "\n"), "\n");
    var acc: score_t = 0;
    while (lines.next()) |line| {
        acc += (try parse_round(line)).score();
    }
    return acc;
}

test "score_game" {
    const t = std.testing;
    const text =
        \\A Y
        \\B X
        \\C Z
    ;

    try t.expectEqual(@as(score_t, 15), try score_game(text));
}

pub fn main() !void {}
