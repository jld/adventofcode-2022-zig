const std = @import("std");

pub fn main() !void {
    const food_t = i64;
    const max_input: usize = 0x8000_0000;

    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!general_purpose_allocator.deinit());
    const gpa = general_purpose_allocator.allocator();

    var input = try stdin.readAllAlloc(gpa, max_input);
    defer gpa.free(input);

    var lines = std.mem.split(u8, std.mem.trimRight(u8, input, "\n"), "\n");
    var elves = std.ArrayList(food_t).init(gpa);
    defer elves.deinit();

    var acc: food_t = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            try elves.append(acc);
            acc = 0;
            continue;
        }
        const snack = try std.fmt.parseUnsigned(food_t, line, 10);
        acc += snack;
    }
    try elves.append(acc);

    try stdout.print("Max Elf: {}\n", .{std.mem.max(food_t, elves.items)});

    try bw.flush();
}
