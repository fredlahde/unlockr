# AGENTS.md

This file provides guidance for AI coding agents working in this repository.

## Project Overview

**unlockr** is a small Zig CLI tool that wraps `cryptsetup` and `mount`/`umount`
to simplify working with LUKS-encrypted containers. It reads configuration from
`/etc/unlockr/config.json` and exposes two commands: `lock` and `unlock`.

Architecture: library module (`src/root.zig`) + executable entry point (`src/main.zig`).
The executable imports the library as `"unlockr_lib"` (configured in `build.zig`).

## Build Commands

```bash
# Build (debug)
zig build

# Build (release)
zig build --release=safe

# Run the app (passes args after --)
zig build run -- unlock
zig build run -- lock

# Run all unit tests (both lib and exe modules)
zig build test

# Format all Zig source files
zig fmt src/
zig fmt build.zig

# Format a single file
zig fmt src/root.zig
```

### Using the justfile (task runner)

```bash
just build              # zig build
just unlock             # build + sudo run unlock
just lock               # build + sudo run lock
just install            # release build + install binary to /usr/bin/unlockr
just install-sample-config  # install sample config to /etc/unlockr/
```

## Testing

Zig's built-in test framework is used. Tests are declared inline in source files
using `test "name" { ... }` blocks.

```bash
# Run all tests (lib + exe modules)
zig build test

# Run only library tests
zig test src/root.zig

# Run only a specific named test (by filter string)
zig test src/root.zig --test-filter "test name substring"
```

The build system defines two test targets in `build.zig`:
- `lib_unit_tests` -- tests from `src/root.zig`
- `exe_unit_tests` -- tests from `src/main.zig`

When adding tests, place them in the same file as the code they test, using
`test "descriptive name" { ... }` blocks at the bottom of the file. Use
`std.testing.expect`, `std.testing.expectEqual`, `std.testing.expectEqualStrings`,
etc. for assertions.

## CI

GitHub Actions workflow (`.github/workflows/main.yml`) runs on pushes and PRs to
`main`. It builds the Zig compiler from source and runs `zig build test`.

## Code Style Guidelines

### Formatting

- Use `zig fmt` for all formatting -- it is the single source of truth.
- 4-space indentation (enforced by `zig fmt`).
- No trailing whitespace.
- Opening braces on the same line; closing braces on their own line.

### Imports

- `@import("std")` comes first, at the top of the file.
- Module-level aliases for frequently used types go immediately after imports:
  ```zig
  const std = @import("std");
  const Allocator = std.mem.Allocator;
  ```
- Library imports use the module name from `build.zig`:
  ```zig
  const lib = @import("unlockr_lib");
  ```
- Short aliases for stdlib utilities are acceptable:
  ```zig
  const eql = std.mem.eql;
  ```

### Naming Conventions

- **Functions**: `snake_case` (e.g., `read_config`, `unlock_luks`, `un_mount`).
- **Types/Structs**: `PascalCase` (e.g., `Config`, `Allocator`).
- **Constants**: `snake_case` (e.g., `config_file`).
- **Variables**: `snake_case` (e.g., `run_cmd`, `fba`).
- **File names**: `snake_case.zig` (e.g., `root.zig`, `main.zig`).

### Types

- Use explicit types for function parameters and return values.
- Use `[]const u8` for string slices that won't be modified; `[]u8` for mutable.
- Prefer `const` over `var` unless mutation is needed.
- Use Zig's type inference (`const x = ...`) for local variables where the type
  is obvious from context.

### Error Handling

- Functions that can fail return `!T` (error union).
- Use `try` to propagate errors up to the caller.
- Use `@panic("message")` only for truly unrecoverable programmer errors
  (e.g., invalid CLI arguments in `main`).
- Do not silently discard errors. If ignoring a return value, use `_ = expr`.
- Use `defer` for cleanup (e.g., closing file descriptors):
  ```zig
  var fd = try std.fs.openFileAbsolute(path, .{});
  defer _ = fd.close();
  ```

### Memory Management

- Accept an `Allocator` parameter rather than using a global allocator.
- The executable uses a fixed-buffer allocator (`FixedBufferAllocator`) with a
  1 MB stack buffer -- no heap allocations at runtime.
- Functions that allocate should document this via their `Allocator` parameter.

### Process Spawning

- Use `std.process.Child` for spawning external processes.
- Build argv as a fixed-size array literal `[_][]const u8{ ... }`.
- Always call `proc.spawn()` then `proc.wait()`.

### Documentation Comments

- Use `//!` for module-level doc comments (top of file).
- Use `///` for public function/type doc comments.
- Use `//` for inline explanatory comments.

### File Organization

- `src/root.zig` -- library code (all core logic, public API).
- `src/main.zig` -- executable entry point (CLI parsing, delegates to library).
- `build.zig` -- build configuration.
- `build.zig.zon` -- package manifest.
- Keep the library/executable split: business logic in `root.zig`, CLI glue in
  `main.zig`.

### Configuration

- Runtime config is JSON, read from `/etc/unlockr/config.json`.
- Config path is a module-level `const`.
- The `Config` struct fields map 1:1 to JSON keys.
- `config.json.sample` is the template; never commit real config values.

## Dependencies

Currently zero external dependencies. If adding one, use `zig fetch --save <url>`
which updates `build.zig.zon`.

## License

Apache License 2.0.
