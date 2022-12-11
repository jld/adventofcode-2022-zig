const std = @import("std");
const util = @import("aoc-util");

const food_t = i64;

const ElfInfo = struct {
    max: food_t,
    top3: ?food_t = null,
};

fn elf_info(alloc: std.mem.Allocator, input: []const u8) !ElfInfo {
    var lines = util.lines(input);
    var elf_buf = std.ArrayList(food_t).init(alloc);
    defer elf_buf.deinit();

    var acc: food_t = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            try elf_buf.append(acc);
            acc = 0;
            continue;
        }
        const snack = try std.fmt.parseUnsigned(food_t, line, 10);
        acc += snack;
    }
    try elf_buf.append(acc);
    const elves = elf_buf.items;

    var rv = ElfInfo{ .max = std.mem.max(food_t, elves) };
    if (elves.len >= 3) {
        std.sort.sort(food_t, elves, {}, comptime std.sort.desc(food_t));
        rv.top3 = elves[0] + elves[1] + elves[2];
    }
    return rv;
}

fn io_main(ctx: util.IOContext) !void {
    const info = try elf_info(ctx.gpa, ctx.input);
    try ctx.stdout.print("Max Elf: {}\n", .{info.max});

    if (info.top3) |top3| {
        try ctx.stdout.print("Top 3: {}\n", .{top3});
    }
}

pub fn main() !void {
    try util.io_shell(io_main);
}

const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

test "day01 example 1" {
    const input =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;
    const info = try elf_info(test_allocator, input);
    try expect(info.max == 24000);
    try expect(info.top3.? == 45000);
}
