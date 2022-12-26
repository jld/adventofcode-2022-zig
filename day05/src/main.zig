const std = @import("std");
const util = @import("aoc-util");

const assert = std.debug.assert;

const Stack = std.ArrayList(u8);

const Mov = struct {
    n: usize,
    src: usize,
    dst: usize,

    fn expect(self: *const Mov, xn: usize, xs: usize, xd: usize) !void {
        try std.testing.expectEqual(xn, self.n);
        try std.testing.expectEqual(xs, self.src);
        try std.testing.expectEqual(xd, self.dst);
    }
};

const State = struct {
    stacks: [9]Stack,

    fn init(alloc: std.mem.Allocator) State {
        var self = State{ .stacks = undefined };
        for (self.stacks) |*out| {
            out.* = Stack.init(alloc);
        }
        return self;
    }
    fn deinit(self: *State) void {
        for (self.stacks) |*stk| {
            stk.deinit();
        }
    }

    fn move(self: *State, mov: Mov) !void {
        var i: usize = 0;
        while (i < mov.n) : (i += 1) {
            const crate = self.stacks[mov.src].popOrNull() orelse return error.EmptyStack;
            try self.stacks[mov.dst].append(crate);
        }
    }

    fn add(self: *State, idx: usize, crate: u8) !void {
        return self.stacks[idx].append(crate);
    }
    fn add_n(self: *State, idx: usize, crates: []const u8) !void {
        return self.stacks[idx].appendSlice(crates);
    }

    fn check(self: *State, idx: usize, crates: []const u8) bool {
        return std.mem.eql(u8, self.stacks[idx].items, crates);
    }

    fn top(self: *const State, idx: usize) ?u8 {
        const stk = self.stacks[idx].items;
        return if (stk.len == 0) null else stk[stk.len - 1];
    }

    fn message(self: *const State) [9]u8 {
        var rv: [9]u8 = undefined;
        for (rv) |*out, i| {
            out.* = self.top(i) orelse ' ';
        }
        return rv;
    }

    fn flip(self: *State) void {
        for (self.stacks) |*stk| {
            std.mem.reverse(u8, stk.items);
        }
    }
};

test "State/create" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try s.add_n(0, "ZN");
    try s.add_n(1, "MCD");
    try s.add_n(2, "P");

    try t.expect(s.check(0, "ZN"));
    try t.expect(s.check(1, "MCD"));
    try t.expect(s.check(2, "P"));

    try t.expect(s.check(3, ""));
    try t.expect(!s.check(0, "ZNX"));
    try t.expect(!s.check(0, "Z"));
    try t.expect(!s.check(0, "ZZ"));
}

test "State/message" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try s.add_n(0, "C");
    try s.add_n(1, "M");
    try s.add_n(2, "PDNZ");

    try t.expect(std.mem.eql(u8, &s.message(), "CMZ      "));
}

test "State/move" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try s.add_n(0, "ZN");
    try s.add_n(1, "MCD");
    try s.add_n(2, "P");

    try s.move(.{ .n = 1, .src = 1, .dst = 0 });
    try t.expect(s.check(0, "ZND"));
    try t.expect(s.check(1, "MC"));
    try t.expect(s.check(2, "P"));

    try s.move(.{ .n = 3, .src = 0, .dst = 2 });
    try t.expect(s.check(0, ""));
    try t.expect(s.check(1, "MC"));
    try t.expect(s.check(2, "PDNZ"));

    try s.move(.{ .n = 2, .src = 1, .dst = 0 });
    try t.expect(s.check(0, "CM"));
    try t.expect(s.check(1, ""));
    try t.expect(s.check(2, "PDNZ"));

    try s.move(.{ .n = 1, .src = 0, .dst = 1 });
    try t.expect(s.check(0, "C"));
    try t.expect(s.check(1, "M"));
    try t.expect(s.check(2, "PDNZ"));
}

fn check_word(exp: []const u8, act: []const u8) !void {
    if (!std.mem.eql(u8, exp, act)) {
        // std.debug.print("Keyword error: expected {s}, got {s}\n", .{ exp, act });
        return error.BadKeyword;
    }
}

fn parse_loc(word: []const u8) !usize {
    if (word.len != 1 or word[0] < '1' or word[0] > '9') {
        return error.Overflow;
    }
    return @as(usize, word[0] - '1');
}

fn parse_move(line: []const u8) !Mov {
    const words = try util.split_n(line, " ", 6);
    try check_word("move", words[0]);
    try check_word("from", words[2]);
    try check_word("to", words[4]);
    return Mov{
        .n = try std.fmt.parseUnsigned(usize, words[1], 10),
        .src = try parse_loc(words[3]),
        .dst = try parse_loc(words[5]),
    };
}

test "parse_move" {
    const t = std.testing;

    const m0 = try parse_move("move 3 from 1 to 2");
    try m0.expect(3, 0, 1);

    const m1 = try parse_move("move 23 from 7 to 1");
    try m1.expect(23, 6, 0);

    const m2 = try parse_move("move 0 from 9 to 5");
    try m2.expect(0, 8, 4);

    try t.expectError(error.Overflow, parse_move("move 5 from 3 to 0"));
    try t.expectError(error.Overflow, parse_move("move 5 from 3 to 10"));
    try t.expectError(error.InvalidCharacter, parse_move("move -1 from 4 to 5"));
    try t.expectError(error.BadKeyword, parse_move("copy 2 from 1 to 3"));
    try t.expectError(error.BadKeyword, parse_move("move 2 to 1 from 3"));
}

fn parse_boxline(state: *State, line: []const u8) !bool {
    if (@mod(line.len, 4) != 3) {
        return error.RaggedLine;
    }

    var i: usize = 3;
    while (i < line.len) : (i += 4) {
        if (line[i] != ' ') {
            return error.BadColumnBreak;
        }
    }

    if (line[0] == ' ' and line[1] != ' ') {
        i = 0;
        while (i < line.len) : (i += 4) {
            assert(i + 2 < line.len);
            if (line[i] != ' ' or line[i + 2] != ' ') {
                return error.BadNumberPad;
            }
            if (line[i + 1] != '1' + @intCast(u8, i / 4)) {
                return error.BadColumnNumber;
            }
        }
        return false;
    }

    i = 0;
    while (i < line.len) : (i += 4) {
        assert(i + 2 < line.len);
        if (line[i] == ' ') {
            if (line[i + 1] != ' ' or line[i + 2] != ' ') {
                return error.CrateSyntax;
            }
            continue;
        }
        if (line[i] != '[' or line[i + 2] != ']') {
            return error.CrateSyntax;
        }
        try state.add(i / 4, line[i + 1]);
    }
    return true;
}

test "parse_boxline/ret" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try t.expect(try parse_boxline(&s, "[A]"));
    try t.expect(try parse_boxline(&s, "[A] [B]"));
    try t.expect(try parse_boxline(&s, "    [C]"));
    try t.expect(try parse_boxline(&s, "        [D]     [E]"));

    try t.expect(!try parse_boxline(&s, " 1   2   3 "));
    try t.expect(!try parse_boxline(&s, " 1 "));
    try t.expect(!try parse_boxline(&s, " 1   2   3   4   5   6   7   8   9 "));
}

test "parse_boxline/err" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try t.expectError(error.RaggedLine, parse_boxline(&s, ""));
    try t.expectError(error.RaggedLine, parse_boxline(&s, "X"));
    try t.expectError(error.RaggedLine, parse_boxline(&s, " 1"));
    try t.expectError(error.RaggedLine, parse_boxline(&s, "[X] "));

    try t.expectError(error.BadColumnBreak, parse_boxline(&s, "[A]-[B]"));
    try t.expectError(error.BadNumberPad, parse_boxline(&s, " 1  [2]"));
    try t.expectError(error.BadColumnNumber, parse_boxline(&s, " 1   2   5   4 "));
    try t.expectError(error.BadColumnNumber, parse_boxline(&s, " A   B   C "));

    try t.expectError(error.CrateSyntax, parse_boxline(&s, "(A)"));
    try t.expectError(error.CrateSyntax, parse_boxline(&s, "[A   B]"));
    try t.expectError(error.CrateSyntax, parse_boxline(&s, "[A]  B "));
    try t.expectError(error.CrateSyntax, parse_boxline(&s, "  A"));

    try t.expectError(error.BadColumnBreak, parse_boxline(&s, "move 10 from 2 to 3"));
}

test "parse_boxline/stk" {
    const t = std.testing;
    var s = State.init(t.allocator);
    defer s.deinit();

    try t.expect(try parse_boxline(&s, "    [D]"));
    try t.expect(try parse_boxline(&s, "[N] [C]"));
    try t.expect(try parse_boxline(&s, "[Z] [M] [P]"));
    try t.expect(!try parse_boxline(&s, " 1   2   3 "));

    s.flip();

    try t.expect(s.check(0, "ZN"));
    try t.expect(s.check(1, "MCD"));
    try t.expect(s.check(2, "P"));
}

fn rearrange_p1(allocator: std.mem.Allocator, input: []const u8) !State {
    var state = State.init(allocator);
    errdefer state.deinit();

    var lines = util.lines(input);
    while (true) {
        const line = lines.next() orelse return error.TruncatedInput;
        if (!try parse_boxline(&state, line)) {
            const empty = lines.next() orelse return error.TruncatedInput;
            if (empty.len != 0) {
                return error.BadSectionBreak;
            }
            break;
        }
    }
    state.flip();

    while (lines.next()) |line| {
        try state.move(try parse_move(line));
    }

    return state;
}

test "rearrange_p1" {
    const t = std.testing;
    // N.B. there is load-bearing trailing whitespace here:
    const example =
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    ;

    var s = try rearrange_p1(t.allocator, example);
    defer s.deinit();

    try t.expect(s.check(0, "C"));
    try t.expect(s.check(1, "M"));
    try t.expect(s.check(2, "PDNZ"));
}

pub fn main() !void {}
