const std = @import("std");

// https://ziglang.org/learn/build-system

const name = "zevm";

pub fn build(b: *std.Build) void {
    const emit = b.option(bool, "emit", "emit assembly and LLVM-IR") orelse false;
    const use_llvm = if (b.option(bool, "no-use-llvm", "don't use LLVM -- doesn't work yet")) |v| !v else null;
    const strip = b.option(bool, "strip", "strip executable");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const evmc = b.addTranslateC(.{
        .root_source_file = b.path("evmc/include/evmc/evmc.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .use_clang = true,
    });
    const evmc_module = evmc.createModule();

    const main_module = b.addModule(name, .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
    });
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = main_module,
        .use_lld = use_llvm,
        .use_llvm = use_llvm,
    });
    exe.root_module.addImport("evmc", evmc_module);

    if (emit and (use_llvm orelse true)) { // TODO: non-LLVM doesn't emit assembly
        const install_asm = b.addInstallFile(exe.getEmittedAsm(), name ++ ".s");
        b.getInstallStep().dependOn(&install_asm.step);

        if (use_llvm orelse true) {
            const install_llvm_ir = b.addInstallFile(exe.getEmittedLlvmIr(), name ++ ".ll");
            b.getInstallStep().dependOn(&install_llvm_ir.step);
        }
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_module = main_module,
    });
    unit_tests.root_module.addImport("evmc", evmc_module);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
