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
