const std = @import("std");
const util = @import("aoc-util");
const Allocator = std.mem.Allocator;

const Trees = struct {
    const Self = @This();

    allocator: Allocator,
    hmap: []u8,
    xdim: usize,
    ydim: usize,

    fn init(a: Allocator) Self {
        return .{
            .allocator = a,
            .hmap = &[_]u8{},
            .xdim = 0,
            .ydim = 0,
        };
    }
    fn deinit(self: *Self) void {
        self.allocator.free(self.hmap);
    }

    fn parse(allocator: Allocator, input: []const u8) !Self {
        var self = init(allocator);
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();

        var lines = util.lines(input);
        const line0 = lines.first();
        self.xdim = line0.len;
        self.ydim = 1;
        try buf.appendSlice(line0);
        while (lines.next()) |line| {
            if (line.len != self.xdim) {
                return error.RaggedLines;
            }
            self.ydim += 1;
            try buf.appendSlice(line);
        }
        for (buf.items) |*byte| {
            if (byte.* < '0' or byte.* > '9') {
                return error.Overflow;
            }
            byte.* -= '0';
        }
        self.hmap = try buf.toOwnedSlice();
        return self;
    }
};

fn io_main(ctx: util.IOContext) !void {
    var tr = try Trees.parse(ctx.gpa, ctx.input);
    defer tr.deinit();

    try ctx.stdout.print("{}x{}\n", .{ tr.xdim, tr.ydim });
}

pub fn main() !void {
    try util.io_shell(io_main);
}
