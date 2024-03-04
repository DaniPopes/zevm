const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn lt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = @intFromBool(value < top.*);
}

pub fn gt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = @intFromBool(value > top.*);
}

pub fn slt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    const a = @as(i256, @bitCast(value));
    const b = @as(i256, @bitCast(top.*));
    top.* = @intFromBool(a < b);
}

pub fn sgt(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    const a = @as(i256, @bitCast(value));
    const b = @as(i256, @bitCast(top.*));
    top.* = @intFromBool(a > b);
}

pub fn eq(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = @intFromBool(value == top.*);
}

pub fn iszero(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const top = try int.stack.top();
    top.* = @intFromBool(top.* == 0);
}
