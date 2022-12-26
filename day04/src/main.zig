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
};

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

fn io_main(ctx: util.IOContext) !void {
    _ = ctx;
}

pub fn main() !void {
    try util.io_shell(io_main);
}
