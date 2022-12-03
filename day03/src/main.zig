const std = @import("std");
const prio_t = i64;

fn prio_of_char(c: u8) !prio_t {
    return switch (c) {
        'a'...'z' => c - 'a' + 1,
        'A'...'Z' => c - 'A' + 27,
        else => error.BadCharacter,
    };
}

test "prio_of_char" {
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
        try t.expectEqual(@as(prio_t, case[0]), try prio_of_char(case[1]));
    }
}

test "prio_of_char bad" {
    const t = std.testing;

    inline for (.{ ' ', '@', '[', '_', '0' }) |c| {
        try t.expectError(error.BadCharacter, prio_of_char(c));
    }
}

pub fn main() !void {}
