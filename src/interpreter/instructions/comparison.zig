const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gass;
const InstructionResult = Interpreter.InstructionResult;

pub fn lt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = @intFromBool(a < b.*);
}

pub fn gt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = @intFromBool(a > b.*);
}

pub fn slt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a_, const b_ = try int.stack.popTop();
    const a: i256 = @bitCast(a_);
    const b: i256 = @bitCast(b_.*);
    b_.* = @intFromBool(a < b);
}

pub fn sgt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a_, const b_ = try int.stack.popTop();
    const a: i256 = @bitCast(a_);
    const b: i256 = @bitCast(b_.*);
    b_.* = @intFromBool(a > b);
}

pub fn eq(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a, const b = try int.stack.popTop();
    b.* = @intFromBool(a == b.*);
}

pub fn iszero(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const a = try int.stack.top();
    a.* = @intFromBool(a.* == 0);
}
