const std = @import("std");
const builtin = @import("builtin");

const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gas;
const Instruction = Interpreter.InstructionPtr;
const InstructionResult = Interpreter.InstructionResult;
const utils = @import("utils.zig");

pub fn pop(int: *Interpreter) !void {
    try int.recordGas(gas.base);
    _ = try int.stack.pop();
}

pub fn push0(int: *Interpreter) !void {
    try int.recordGas(gas.base);
    return int.stack.push(0);
}

pub fn push(comptime n: comptime_int) Instruction {
    if (n == 0 or n > 32) {
        @compileError("invalid push instruction");
    }

    const pushT = struct {
        fn push(int: *Interpreter) !void {
            asmComment(std.fmt.comptimePrint("push{}", .{n}));
            try int.recordGas(gas.verylow);
            const toPush = try int.readBytes(n);
            var padded: [32]u8 = comptime [_]u8{0} ** 32;
            @memcpy(padded[32 - n ..], toPush);
            try int.stack.pushBeBytes(padded);
            int.ip += n;
        }
    };
    return pushT.push;
}

pub fn dup(comptime n: comptime_int) Instruction {
    if (n == 0 or n > 16) {
        @compileError("invalid dup instruction");
    }

    const dupT = struct {
        fn dup(int: *Interpreter) !void {
            asmComment(std.fmt.comptimePrint("dup{}", .{n}));
            try int.recordGas(gas.verylow);
            return int.stack.dup(n);
        }
    };
    return dupT.dup;
}

pub fn swap(comptime n: comptime_int) Instruction {
    if (n == 0 or n > 16) {
        @compileError("invalid swap instruction");
    }

    const swapT = struct {
        fn swap(int: *Interpreter) !void {
            try int.recordGas(gas.verylow);
            asmComment(std.fmt.comptimePrint("swap{}", .{n}));
            return int.stack.swap(n);
        }
    };
    return swapT.swap;
}

pub fn dupn(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const imm = try int.readByte();
    try int.stack.dup(@as(usize, @intCast(imm)) + 1);
    int.ip += 1;
}

pub fn swapn(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const imm = try int.readByte();
    try int.stack.swap(@as(usize, @intCast(imm)) + 1);
    int.ip += 1;
}

pub fn exchange(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const imm = try int.readByte();
    const n = (imm >> 4) + 1;
    const m = (imm & 15) + 1;
    try int.stack.exchange(n, m);
    int.ip += 1;
}

inline fn asmComment(comptime s: []const u8) void {
    if (comptime builtin.cpu.arch.isX86() and builtin.abi.isGnu()) {
        asm volatile ("# " ++ s);
    }
}
