const std = @import("std");
const item_t = u6;

fn item_of_char(c: u8) !item_t {
    return switch (c) {
        'a'...'z' => @intCast(u6, c - 'a') + 1,
        'A'...'Z' => @intCast(u6, c - 'A') + 27,
        else => error.BadCharacter,
    };
}

test "item_of_char" {
    const t = std.testing;
    const cases = .{
        .{ 16, 'p' },
        .{ 38, 'L' },
        .{ 42, 'P' },
        .{ 22, 'v' },
        .{ 20, 't' },
        .{ 19, 's' },
        .{ 26, 'z' },
        .{ 52, 'Z' },
    };

    inline for (cases) |case| {
        try t.expectEqual(@as(item_t, case[0]), try item_of_char(case[1]));
    }
}

test "item_of_char bad" {
    const t = std.testing;

    inline for (.{ ' ', '@', '[', '_', '0' }) |c| {
        try t.expectError(error.BadCharacter, item_of_char(c));
    }
}

const Sack = struct {
    bits: u52 = 0,

    fn item_mask(item: item_t) u52 {
        std.debug.assert(item >= 1 and item <= 52);
        return @as(u52, 1) << (item - 1);
    }

    fn add(self: *Sack, item: item_t) void {
        self.bits |= Sack.item_mask(item);
    }
    fn has(self: Sack, item: item_t) bool {
        return (self.bits & Sack.item_mask(item)) != 0;
    }

    fn add_str(self: *Sack, str: []const u8) !void {
        for (str) |chr| {
            self.add(try item_of_char(chr));
        }
    }

    fn isect(self: Sack, other: Sack) Sack {
        return Sack{ .bits = self.bits & other.bits };
    }

    fn unpack(self: Sack, comptime count: usize, out: *[count]item_t) !void {
        var i: usize = 0;
        var bits = self.bits;
        while (bits != 0) {
            if (i >= count) {
                return error.SackTooBig;
            }
            const item: item_t = @ctz(bits) + 1;
            bits &= ~Sack.item_mask(item);
            out[i] = item;
            i += 1;
        }
        if (i < count) {
            return error.SackTooSmall;
        }
    }
};

test "Sack add/has" {
    const t = std.testing;

    var sack = Sack{};
    try t.expect(!sack.has(1));
    try t.expect(!sack.has(52));

    sack.add(3);
    try t.expect(sack.has(3));
    try t.expect(!sack.has(1));
    try t.expect(!sack.has(35));
    try t.expect(!sack.has(52));

    sack.add(1);
    try t.expect(sack.has(3));
    try t.expect(sack.has(1));
    try t.expect(!sack.has(33));
    try t.expect(!sack.has(35));
    try t.expect(!sack.has(52));

    sack.add(52);
    try t.expect(sack.has(3));
    try t.expect(sack.has(1));
    try t.expect(sack.has(52));
    try t.expect(!sack.has(20));
    try t.expect(!sack.has(33));
    try t.expect(!sack.has(35));
}

test "Sack add_str" {
    const t = std.testing;

    var sack = Sack{};
    try sack.add_str("vJrwpWtwJgWr");
    try t.expect(sack.has(16));
    try t.expect(sack.has(18));
    try t.expect(sack.has(36));
    try t.expect(!sack.has(38));

    sack = Sack{};
    try sack.add_str("hcsFMMfFFhFp");
    try t.expect(sack.has(16));
    try t.expect(sack.has(19));
    try t.expect(sack.has(32));
    try t.expect(!sack.has(38));
}

test "Sack isect" {
    const t = std.testing;

    var sack_l = Sack{};
    var sack_r = Sack{};
    try sack_l.add_str("vJrwpWtwJgWr");
    try sack_r.add_str("hcsFMMfFFhFp");
    const sack = sack_l.isect(sack_r);
    try t.expect(sack.has(16));
    try t.expect(!sack.has(18));
    try t.expect(!sack.has(19));
    try t.expect(!sack.has(32));
    try t.expect(!sack.has(36));
    try t.expect(!sack.has(38));
}

test "Sack unpack" {
    const t = std.testing;

    var sack_0 = Sack{};
    var sack_1 = sack_0;
    sack_1.add(16);
    var sack_3 = sack_1;
    sack_3.add(38);
    sack_3.add(2);

    var buf_0: [0]item_t = undefined;
    var buf_1: [1]item_t = undefined;
    var buf_3: [3]item_t = undefined;

    try t.expectError(error.SackTooBig, sack_1.unpack(0, &buf_0));
    try t.expectError(error.SackTooSmall, sack_0.unpack(1, &buf_1));
    try t.expectError(error.SackTooBig, sack_3.unpack(1, &buf_1));
    try t.expectError(error.SackTooSmall, sack_1.unpack(3, &buf_3));

    try sack_0.unpack(0, &buf_0);
    try sack_1.unpack(1, &buf_1);
    try t.expect(buf_1[0] == 16);
    try sack_3.unpack(3, &buf_3);
    try t.expect(buf_3[0] == 2);
    try t.expect(buf_3[1] == 16);
    try t.expect(buf_3[2] == 38);
}

pub fn main() !void {}
