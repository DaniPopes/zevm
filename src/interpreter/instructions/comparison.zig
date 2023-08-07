const std = @import("std");

const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn lt(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = @intFromBool(x.value < x.top.*);
}

pub fn gt(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = @intFromBool(x.value > x.top.*);
}

pub fn slt(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn sgt(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn eq(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = @intFromBool(x.value == x.top.*);
}

pub fn iszero(int: *Interpreter) !void {
    var top = try int.stack.top();
    top.* = @intFromBool(top.* == 0);
}
