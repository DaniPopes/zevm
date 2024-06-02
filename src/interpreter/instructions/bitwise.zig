const std = @import("std");
const little_endian = @import("builtin").cpu.arch.endian() == .little;

const Interpreter = @import("../Interpreter.zig");
const utils = @import("utils.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn bitand(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = a & b.*;
}

pub fn bitor(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = a | b.*;
}

pub fn bitxor(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = a ^ b.*;
}

pub fn bitnot(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a = try int.stack.top();
    a.* = ~a.*;
}

pub fn byte(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const idx_, const a = try int.stack.popTop();
    if (idx_ < 32) {
        var idx: usize = @intCast(idx_);
        // `byte` uses big-endian
        if (little_endian) {
            idx = 31 - idx;
        }
        const bytes: *[32]u8 = @ptrCast(a);
        a.* = bytes[idx];
    } else {
        a.* = 0;
    }
}

pub fn shl(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const shift, const a = try int.stack.popTop();
    if (shift < 256) {
        a.* <<= @intCast(shift);
    } else {
        a.* = 0;
    }
}

pub fn shr(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const shift, const a = try int.stack.popTop();
    if (shift < 256) {
        a.* >>= @intCast(shift);
    } else {
        a.* = 0;
    }
}

pub fn sar(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const shift, const a = try int.stack.popTop();
    const ix: i256 = @bitCast(a.*);
    if (shift < 256) {
        a.* = @bitCast(ix >> @intCast(shift));
    } else {
        a.* = if (ix < 0) std.math.maxInt(u256) else 0;
    }
}
