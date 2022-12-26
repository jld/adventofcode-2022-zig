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
};

test "contains" {
    const t = std.testing;
    const e28 = Elf{ .lo = 2, .hi = 8 };
    const e37 = Elf{ .lo = 3, .hi = 7 };
    const e66 = Elf{ .lo = 6, .hi = 6 };
    const e46 = Elf{ .lo = 4, .hi = 6 };

    try t.expect(e28.contains(e37));
    try t.expect(e46.contains(e66));

    try t.expect(!e37.contains(e28));
    try t.expect(!e66.contains(e46));

    try t.expect(e37.contains(e37));
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

fn io_main(ctx: util.IOContext) !void {
    _ = ctx;
}

pub fn main() !void {
    try util.io_shell(io_main);
}
