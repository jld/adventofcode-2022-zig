const std = @import("std");
const util = @import("aoc-util");

const reg_t = i64;
const time_t = u32;

const Insn = union(enum) {
    noop,
    addx: reg_t,

    fn parse(line: []const u8) !Insn {
        var words = std.mem.tokenize(u8, line, " ");
        const opcode = words.next() orelse return error.EmptyLine;
        if (std.mem.eql(u8, opcode, "noop")) {
            return Insn.noop;
        }
        if (std.mem.eql(u8, opcode, "addx")) {
            const arg = words.next() orelse return error.MissingArg;
            return Insn{ .addx = try std.fmt.parseInt(reg_t, arg, 10) };
        }
        return error.BadOpcode;
    }

    fn time(self: Insn) time_t {
        return switch (self) {
            Insn.noop => 1,
            Insn.addx => 2,
        };
    }
};

const CPU = struct {
    imem: []const Insn,
    pc: usize = 0,
    cooldown: time_t = 0,
    x: reg_t = 1,

    fn init(prog: []const Insn) CPU {
        return .{ .imem = prog };
    }

    fn do_insn(self: *CPU, insn: Insn) void {
        switch (insn) {
            Insn.noop => {},
            Insn.addx => |dx| self.x += dx,
        }
    }

    fn tick(self: *CPU) bool {
        if (self.pc >= self.imem.len) {
            return false;
        }
        if (self.cooldown == 0) {
            self.cooldown = self.imem[self.pc].time();
        }
        self.cooldown -= 1;
        if (self.cooldown == 0) {
            const insn = self.imem[self.pc];
            self.pc += 1;
            self.do_insn(insn);
        }
        return true;
    }
};

fn parse_prog(a: std.mem.Allocator, input: []const u8) ![]Insn {
    var buf = std.ArrayList(Insn).init(a);
    errdefer buf.deinit();
    var lines = util.lines(input);
    while (lines.next()) |line| {
        try buf.append(try Insn.parse(line));
    }
    return buf.toOwnedSlice();
}

test "small example" {
    const t = std.testing;
    const example =
        \\noop
        \\addx 3
        \\addx -5
    ;

    const prog = try parse_prog(t.allocator, example);
    defer t.allocator.free(prog);
    var cpu = CPU.init(prog);
    try t.expect(cpu.tick());
    try t.expectEqual(@as(reg_t, 1), cpu.x);
    try t.expect(cpu.tick());
    try t.expectEqual(@as(reg_t, 1), cpu.x);
    try t.expect(cpu.tick());
    try t.expectEqual(@as(reg_t, 4), cpu.x);
    try t.expect(cpu.tick());
    try t.expectEqual(@as(reg_t, 4), cpu.x);
    try t.expect(cpu.tick());
    try t.expectEqual(@as(reg_t, -1), cpu.x);
    try t.expect(!cpu.tick());
}

pub fn main() !void {}
