const std = @import("std");
const little_endian = @import("builtin").cpu.arch.endian() == .little;

const Interpreter = @import("../Interpreter.zig");
const utils = @import("utils.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn bitand(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = value & top.*;
}

pub fn bitor(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = value | top.*;
}

pub fn bitxor(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = value ^ top.*;
}

pub fn bitnot(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const top = try int.stack.top();
    top.* = ~top.*;
}

pub fn byte(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    var byte_idx = utils.castSaturate(usize, value);
    if (byte_idx < 32) {
        const bytes = @as(*[32]u8, @ptrCast(top));
        // `byte` uses big-endian
        if (little_endian) {
            byte_idx = 31 - byte_idx;
        }
        top.* = bytes[byte_idx];
    } else {
        top.* = 0;
    }
}

pub fn shl(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    if (top.* < 256) {
        top.* = value << @as(u8, @intCast(top.*));
    } else {
        top.* = 0;
    }
}

pub fn shr(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    if (top.* < 256) {
        top.* = value >> @as(u8, @intCast(top.*));
    } else {
        top.* = 0;
    }
}

pub fn sar(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value_, const top = try int.stack.popTop();
    const value = @as(i256, @bitCast(value_));
    if (top.* < 256) {
        top.* = @bitCast(value >> @as(u8, @intCast(top.*)));
    } else {
        top.* = if (value < 0) std.math.maxInt(u256) else 0;
    }
}
