//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const Allocator = std.mem.Allocator;

const config_file = "/etc/unlockr/config.json";

pub const Config = struct {
    luks_img: []const u8,
    cryptsetup_name: []const u8,
    mount_point: []const u8,

    fn clone(allocator: Allocator, config: Config) !Config {
        const luks_img = try allocator.dupe(u8, config.luks_img);
        errdefer allocator.free(luks_img);

        const cryptsetup_name = try allocator.dupe(u8, config.cryptsetup_name);
        errdefer allocator.free(cryptsetup_name);

        const mount_point = try allocator.dupe(u8, config.mount_point);
        errdefer allocator.free(mount_point);

        return .{
            .luks_img = luks_img,
            .cryptsetup_name = cryptsetup_name,
            .mount_point = mount_point,
        };
    }

    pub fn deinit(self: Config, allocator: Allocator) void {
        allocator.free(self.luks_img);
        allocator.free(self.cryptsetup_name);
        allocator.free(self.mount_point);
    }
};

fn run_cmd_checked(allocator: Allocator, argv: []const []const u8) !void {
    var proc = std.process.Child.init(argv, allocator);

    try proc.spawn();

    const term = try proc.wait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) return error.CommandFailed;
        },
        else => return error.CommandFailed,
    }
}

pub fn read_config(allocator: Allocator) !Config {
    var fd = try std.fs.openFileAbsolute(config_file, .{});
    defer _ = fd.close();

    const content = try fd.readToEndAlloc(allocator, 16 * 1024);
    defer allocator.free(content);

    const parsed = try std.json.parseFromSlice(Config, allocator, content, .{});
    defer parsed.deinit();

    return try Config.clone(allocator, parsed.value);
}

pub fn unlock_luks(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "cryptsetup",
        "open",
        config.luks_img,
        config.cryptsetup_name,
    };

    try run_cmd_checked(allocator, &argv);
}

pub fn lock_luks(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "cryptsetup",
        "close",
        config.cryptsetup_name,
    };

    try run_cmd_checked(allocator, &argv);
}

pub fn mount(allocator: Allocator, config: Config) !void {
    const mapper_path = try std.fmt.allocPrint(
        allocator,
        "/dev/mapper/{s}",
        .{config.cryptsetup_name},
    );
    defer allocator.free(mapper_path);

    const argv = [_][]const u8{
        "mount",
        "-t",
        "ext4",
        mapper_path,
        config.mount_point,
    };

    try run_cmd_checked(allocator, &argv);
}

pub fn un_mount(allocator: Allocator, config: Config) !void {
    const argv = [_][]const u8{
        "umount",
        config.mount_point,
    };

    try run_cmd_checked(allocator, &argv);
}
