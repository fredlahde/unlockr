const std = @import("std");
const lib = @import("unlockr_lib");
const eql = std.mem.eql;

fn usage_and_exit() noreturn {
    std.debug.print("Usage: unlockr <unlock|lock>\n", .{});
    std.process.exit(2);
}

pub fn main() !void {
    var buffer: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var iter = std.process.args();
    _ = iter.next();
    const cmd: []const u8 = iter.next() orelse usage_and_exit();
    if (iter.next() != null) usage_and_exit();

    const config = try lib.read_config(allocator);
    defer config.deinit(allocator);

    if (eql(u8, cmd, "unlock")) {
        try lib.unlock_luks(allocator, config);
        try lib.mount(allocator, config);
    } else if (eql(u8, cmd, "lock")) {
        try lib.un_mount(allocator, config);
        try lib.lock_luks(allocator, config);
    } else {
        usage_and_exit();
    }
}
