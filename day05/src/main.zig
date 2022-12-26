const std = @import("std");
const util = @import("aoc-util");

const Stack = std.ArrayList(u8);

const Mov = struct {
    n: usize,
    src: usize,
    dst: usize,
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

pub fn main() !void {}
