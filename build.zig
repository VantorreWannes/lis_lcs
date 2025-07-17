const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("lis_lcs", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const use_llvm = b.option(bool, "llvm", "Use the LLVM backend");

    const exe = b.addExecutable(.{
        .name = "lis_lcs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "lis_lcs", .module = mod },
            },
        }),
        .use_llvm = use_llvm,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
        .use_llvm = use_llvm,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);
    const install_mod_tests = b.addInstallArtifact(mod_tests, .{});

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
        .use_llvm = use_llvm,
    });
    
    const run_exe_tests = b.addRunArtifact(exe_tests);
    
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&install_mod_tests.step);
}
