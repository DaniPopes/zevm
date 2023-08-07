const std = @import("std");

const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn add(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value +% x.top.*;
}

pub fn mul(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value *% x.top.*;
}

pub fn sub(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value -% x.top.*;
}

pub fn div(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    if (x.top.* != 0) {
        x.top.* = x.value / x.top.*;
    }
}

pub fn sdiv(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn mod(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    if (x.top.* != 0) {
        x.top.* = x.value % x.top.*;
    }
}

pub fn smod(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn addmod(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn mulmod(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn exp(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn signextend(int: *Interpreter) !void {
    _ = int;
    // TODO
}
