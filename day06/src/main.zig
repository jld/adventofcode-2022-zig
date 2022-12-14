const std = @import("std");
const util = @import("aoc-util");
const BitSet = std.bit_set.DynamicBitSetUnmanaged;
const Allocator = std.mem.Allocator;

fn triangle(a: Allocator, n: usize) ![]BitSet {
    var rv = try a.alloc(BitSet, n);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        rv[i] = try BitSet.initEmpty(a, n - i);
    }
    return rv;
}

const Tableau = struct {
    rows: []BitSet,
    a: Allocator,

    fn init(a: Allocator, comptime T: type, str: []const T, k: usize) !Tableau {
        const n = str.len;
        var rows = try a.alloc(BitSet, k - 1);
        for (rows) |*row, i| {
            const l = n - (i + 1);
            row.* = try BitSet.initEmpty(a, l);
            var j: usize = 0;
            while (j < l) : (j += 1) {
                const rec = if (i == 0) true else rows[i - 1].isSet(j) and rows[i - 1].isSet(j + 1);
                if (rec and str[j] != str[j + (i + 1)]) {
                    row.set(j);
                }
            }
        }
        return Tableau{ .rows = rows, .a = a };
    }

    fn deinit(self: *Tableau) void {
        for (self.rows) |*row| {
            row.deinit(self.a);
        }
        self.a.free(self.rows);
    }

    fn get(self: *const Tableau, k: usize) *const BitSet {
        return &self.rows[k - 2];
    }

    fn findFirst(self: *const Tableau, k: usize) ?usize {
        const ffs = self.get(k).findFirstSet() orelse return null;
        return ffs + k;
    }
};

fn first4(a: Allocator, str: []const u8) !usize {
    var tab = try Tableau.init(a, u8, str, 4);
    defer tab.deinit();
    return tab.findFirst(4) orelse error.NotFound;
}

test "example" {
    const t = std.testing;
    const example = "mjqjpqmgbljsphdztnvjfqwrcgsmlb";

    try t.expectEqual(@as(usize, 7), try first4(t.allocator, example));
}

test "more examples" {
    const t = std.testing;
    const examples = .{
        .{ 5, "bvwbjplbgvbhsrlpgdmjqwftvncz" },
        .{ 6, "nppdvjthqldpwncqszvftbrmjlhg" },
        .{ 10, "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg" },
        .{ 11, "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw" },
    };

    inline for (examples) |example| {
        try t.expectEqual(@as(usize, example[0]), try first4(t.allocator, example[1]));
    }
}

const Starts = struct {
    sop: usize,
    som: usize,
};

fn starts(a: Allocator, str: []const u8) !Starts {
    var tab = try Tableau.init(a, u8, str, 14);
    defer tab.deinit();
    return Starts{
        .sop = tab.findFirst(4) orelse return error.NotFound,
        .som = tab.findFirst(14) orelse return error.NotFound,
    };
}

test "yet more examples" {
    const t = std.testing;
    const examples = .{
        .{ 19, "mjqjpqmgbljsphdztnvjfqwrcgsmlb" },
        .{ 23, "bvwbjplbgvbhsrlpgdmjqwftvncz" },
        .{ 23, "nppdvjthqldpwncqszvftbrmjlhg" },
        .{ 29, "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg" },
        .{ 26, "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw" },
    };

    inline for (examples) |example| {
        const sts = try starts(t.allocator, example[1]);
        try t.expectEqual(try first4(t.allocator, example[1]), sts.sop);
        try t.expectEqual(@as(usize, example[0]), sts.som);
    }
}

fn io_main(ctx: util.IOContext) !void {
    var lines = util.lines(ctx.input);
    while (lines.next()) |line| {
        var sts = try starts(ctx.gpa, line);
        try ctx.stdout.print("{} {}\n", .{ sts.sop, sts.som });
    }
}

pub fn main() !void {
    try util.io_shell(io_main);
}
