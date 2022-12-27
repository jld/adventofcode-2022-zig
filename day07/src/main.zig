const std = @import("std");
const util = @import("aoc-util");
const Allocator = std.mem.Allocator;

const size_t = u63;

const File = packed struct {
    isDir: bool,
    size: size_t,
};

fn parent(file: []const u8) ?[]const u8 {
    if (std.mem.lastIndexOfAny(u8, file, "/")) |i| {
        return file[0..i];
    }
    return null;
}

test "parent" {
    const t = std.testing;

    try t.expectEqualStrings("foo", parent("foo/bar").?);
    try t.expectEqualStrings("foo/bar", parent("foo/bar/baz").?);
    try t.expectEqualStrings("foo", parent("foo/").?);
    try t.expect(null == parent("foo"));
    try t.expect(null == parent(""));

    try t.expectEqualStrings("", parent("/foo").?);
    try t.expectEqualStrings("/foo", parent("/foo/bar").?);
    try t.expectEqualStrings("", parent("/").?);
}

const FileMap = std.hash_map.StringHashMapUnmanaged(File);

const FileSys = struct {
    const Self = @This();
    alloc: Allocator,
    files: FileMap,

    fn init(a: Allocator) Self {
        return .{ .alloc = a, .files = .{} };
    }

    fn deinit(self: *Self) void {
        var entries = self.files.iterator();
        while (entries.next()) |entry| {
            self.alloc.free(entry.key_ptr.*);
        }
        self.files.deinit(self.alloc);
    }

    fn mknod(self: *Self, path: []const u8, file: File) !void {
        var key = try self.alloc.dupe(u8, path);
        errdefer self.alloc.free(key);
        var gpr = try self.files.getOrPut(self.alloc, key);
        if (gpr.found_existing) {
            return error.Exists;
        }
        gpr.value_ptr.* = file;
    }

    fn mkdir(self: *Self, path: []const u8) !void {
        try self.mknod(path, .{ .isDir = true, .size = 0 });
    }

    fn creat(self: *Self, path: []const u8, size: size_t) !void {
        try self.mknod(path, .{ .isDir = false, .size = size });
        var dir = path;
        while (true) {
            dir = parent(dir) orelse break;
            const fptr = self.files.getPtr(dir) orelse return error.Fsck;
            fptr.size += size;
        }
    }

    fn stat(self: *const Self, path: []const u8) ?File {
        return self.files.get(path);
    }
};

test "dirSizes" {
    const t = std.testing;
    var fs = FileSys.init(t.allocator);
    defer fs.deinit();

    try fs.mkdir("");
    try fs.mkdir("/a");
    try fs.mkdir("/a/e");
    try fs.creat("/a/e/i", 584);
    try fs.creat("/a/f", 29116);
    try fs.creat("/a/g", 2557);
    try fs.creat("/a/h.lst", 62596);
    try fs.creat("/b.txt", 14848514);
    try fs.creat("/c.dat", 8504156);
    try fs.mkdir("/d");
    try fs.creat("/d/j", 4060174);
    try fs.creat("/d/d.log", 8033020);
    try fs.creat("/d/d.ext", 5626152);
    try fs.creat("/d/k", 7214296);

    try t.expect(fs.stat("").?.isDir);
    try t.expect(fs.stat("/a").?.isDir);
    try t.expect(!fs.stat("/a/f").?.isDir);
    try t.expect(fs.stat("/a/f/i") == null);

    try t.expectEqual(@as(size_t, 584), fs.stat("/a/e").?.size);
    try t.expectEqual(@as(size_t, 94853), fs.stat("/a").?.size);
    try t.expectEqual(@as(size_t, 24933642), fs.stat("/d").?.size);
    try t.expectEqual(@as(size_t, 48381165), fs.stat("").?.size);
}

const Path = struct {
    buf: std.ArrayList(u8),

    fn init(a: Allocator) Path {
        return Path{ .buf = std.ArrayList(u8).init(a) };
    }
    fn deinit(self: *Path) void {
        self.buf.deinit();
    }
    fn get(self: *const Path) []const u8 {
        return self.buf.items;
    }

    fn down(self: *Path, name: []const u8) !void {
        try self.buf.append('/');
        try self.buf.appendSlice(name);
    }
    fn up(self: *Path) !void {
        const dir = parent(self.get()) orelse return error.IsRoot;
        self.buf.shrinkRetainingCapacity(dir.len);
    }
};

test "Path" {
    const t = std.testing;
    var p = Path.init(t.allocator);
    defer p.deinit();

    try t.expectEqualStrings("", p.get());
    try p.down("a");
    try t.expectEqualStrings("/a", p.get());
    try p.down("e");
    try t.expectEqualStrings("/a/e", p.get());
    try p.down("i");
    try t.expectEqualStrings("/a/e/i", p.get());
    try p.up();
    try t.expectEqualStrings("/a/e", p.get());
    try p.up();
    try t.expectEqualStrings("/a", p.get());
    try p.down("f");
    try t.expectEqualStrings("/a/f", p.get());
    try p.up();
    try p.up();
    try t.expectError(error.IsRoot, p.up());
}

pub fn main() !void {}
