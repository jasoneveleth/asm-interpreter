const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{ .name = "jclj", .root_source_file = .{ .path = "src/main.zig" }, .optimize = optimize, .target = target });
    exe.addAssemblyFile(.{ .path = "src/vm.s" });

    // setup `zig build run`
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
