const std = @import("std");

// I hate this.
const Writer = std.io.BufferedWriter(4096, std.fs.File.Writer).Writer;

pub const IOContext: type = struct {
    input: []const u8,
    stdout: Writer,
    gpa: std.mem.Allocator,
};

const max_input: usize = 0x4000_0000;

pub fn io_shell(main_fn: anytype) !void {
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

    try main_fn(IOContext{
        .input = input,
        .stdout = stdout,
        .gpa = gpa,
    });

    try bw.flush();
}

pub fn lines(input: []const u8) std.mem.SplitIterator(u8) {
    return std.mem.split(u8, std.mem.trimRight(u8, input, "\n"), "\n");
}

pub fn sum_lines(comptime num_t: type, input: []const u8, f: anytype) !num_t {
    var acc: num_t = 0;
    var li = lines(input);
    while (li.next()) |line| {
        acc += try f(line);
    }
    return acc;
}

pub fn split_n(input: []const u8, delim: []const u8, comptime n: usize) ![n][]const u8 {
    var rv: [n][]const u8 = undefined;

    var iter = std.mem.split(u8, input, delim);
    var i: usize = 0;
    while (iter.next()) |thing| {
        if (i >= n) {
            return error.SplitOverflow;
        }
        rv[i] = thing;
        i += 1;
    }
    if (i != n) {
        return error.SplitUnderflow;
    }
    return rv;
}
