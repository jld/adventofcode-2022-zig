const std = @import("std");
const util = @import("aoc-util");

const num_t = u8;

const Elf = struct {
    lo: num_t,
    hi: num_t,

    fn parse(input: []const u8) !Elf {
        const nums = try util.split_n(input, "-", 2);
        return Elf{
            .lo = try std.fmt.parseUnsigned(num_t, nums[0], 10),
            .hi = try std.fmt.parseUnsigned(num_t, nums[1], 10),
        };
    }

    fn contains(self: Elf, other: Elf) bool {
        return other.lo >= self.lo and other.hi <= self.hi;
    }
    fn overlaps(self: Elf, other: Elf) bool {
        // zig fmt: off
        return (self.lo <= other.lo and self.hi >= other.lo)
            or (other.lo <= self.lo and other.hi >= self.lo);
        // zig fmt: on
    }
};

fn elf(lo: num_t, hi: num_t) Elf {
    return Elf{ .lo = lo, .hi = hi };
}

test "contains" {
    const t = std.testing;

    try t.expect(elf(2, 8).contains(elf(3, 7)));
    try t.expect(elf(4, 6).contains(elf(6, 6)));

    try t.expect(!elf(3, 7).contains(elf(2, 8)));
    try t.expect(!elf(6, 6).contains(elf(4, 6)));

    try t.expect(elf(3, 7).contains(elf(3, 7)));
}

test "overlaps" {
    const t = std.testing;
    // The implementation is obviously symmetric so I don't think I
    // need to test self/other swaps.

    try t.expect(!elf(2, 4).overlaps(elf(6, 8)));
    try t.expect(!elf(2, 3).overlaps(elf(4, 5)));
    try t.expect(elf(5, 7).overlaps(elf(7, 9)));
    try t.expect(elf(2, 8).overlaps(elf(3, 7)));
    try t.expect(elf(6, 6).overlaps(elf(4, 6)));
    try t.expect(elf(2, 6).overlaps(elf(4, 8)));
}

const Pair = struct {
    e0: Elf,
    e1: Elf,

    fn parse(input: []const u8) !Pair {
        const elves = try util.split_n(input, ",", 2);
        return Pair{
            .e0 = try Elf.parse(elves[0]),
            .e1 = try Elf.parse(elves[1]),
        };
    }

    fn oops(self: Pair) bool {
        return self.e0.contains(self.e1) or self.e1.contains(self.e0);
    }
};

test "parse" {
    const t = std.testing;
    const example = "2-8,3-7";

    const pex = try Pair.parse(example);
    try t.expectEqual(@as(num_t, 2), pex.e0.lo);
    try t.expectEqual(@as(num_t, 8), pex.e0.hi);
    try t.expectEqual(@as(num_t, 3), pex.e1.lo);
    try t.expectEqual(@as(num_t, 7), pex.e1.hi);
}

test "oops" {
    const t = std.testing;
    const example = .{
        .{ "2-4,6-8", false },
        .{ "2-3,4-5", false },
        .{ "5-7,7-9", false },
        .{ "2-8,3-7", true },
        .{ "6-6,4-6", true },
        .{ "2-6,4-8", false },
    };

    inline for (example) |case| {
        const ee = try Pair.parse(case[0]);
        try t.expectEqual(case[1], ee.oops());
    }
}

fn oops_lineproc(line: []const u8) !usize {
    const ee = try Pair.parse(line);
    return if (ee.oops()) 1 else 0;
}

fn overlap_lineproc(line: []const u8) !usize {
    const ee = try Pair.parse(line);
    return if (ee.e0.overlaps(ee.e1)) 1 else 0;
}

fn io_main(ctx: util.IOContext) !void {
    const p0 = try util.sum_lines(usize, ctx.input, oops_lineproc);
    const p1 = try util.sum_lines(usize, ctx.input, overlap_lineproc);
    try ctx.stdout.print("{} {}\n", .{ p0, p1 });
}

pub fn main() !void {
    try util.io_shell(io_main);
}
