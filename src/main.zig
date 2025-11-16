const std = @import("std");
const lib = @import("unlockr_lib");
const eql = std.mem.eql;

pub fn main() !void {
    var buffer: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();
    _ = iter.next();
    const cmd: []const u8 = iter.next() orelse @panic("you need to pass a cmd: lock or unlock");

    const config = try lib.read_config(allocator);

    if (eql(u8, cmd, "unlock")) {
        try lib.unlock_luks(allocator, config);
        try lib.mount(allocator, config);
    } else if (eql(u8, cmd, "lock")) {
        try lib.un_mount(allocator, config);
        try lib.lock_luks(allocator, config);
    } else {
        @panic("invalid cmd");
    }
}
