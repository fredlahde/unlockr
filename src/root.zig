//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const Allocator = std.mem.Allocator;

const config_file = "/etc/unlockr/config.json";

const Config = struct {
    luks_img: []u8,
    cryptsetup_name: []u8,
    mount_point: []u8,
};

pub fn read_config(allocator: Allocator) !Config {
    var fd = try std.fs.openFileAbsolute(config_file, .{});
    defer fd.close();
    const content = try fd.readToEndAlloc(allocator, 1024);
    const parsed = try std.json.parseFromSlice(Config, allocator, content, .{});
    return parsed.value;
}

pub fn unlock_luks(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "cryptsetup",
        "open",
        config.luks_img,
        config.cryptsetup_name,
    };
    var proc = std.process.Child.init(&argv, allocator);

    try proc.spawn();

    _ = try proc.wait();
}

pub fn lock_luks(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "cryptsetup",
        "close",
        config.cryptsetup_name,
    };
    var proc = std.process.Child.init(&argv, allocator);

    try proc.spawn();

    _ = try proc.wait();
}

pub fn mount(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "mount",
        "-t",
        "ext4",
        try std.fmt.allocPrint(allocator, "/dev/mapper/{s}", .{config.cryptsetup_name}),
        config.mount_point,
    };
    var proc = std.process.Child.init(&argv, allocator);

    try proc.spawn();

    _ = try proc.wait();
}

pub fn un_mount(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "umount",
        try std.fmt.allocPrint(allocator, "/dev/mapper/{s}", .{config.cryptsetup_name}),
    };
    var proc = std.process.Child.init(&argv, allocator);

    try proc.spawn();

    _ = try proc.wait();
}
