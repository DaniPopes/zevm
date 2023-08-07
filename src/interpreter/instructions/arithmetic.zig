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
    var x = try int.stack.popTop();
    // note we're not using `std.math.powi` because we want wrapping behaviour
    var value = x.value;
    var exponent = x.top.*;
    var result: u256 = 1;
    while (exponent > 1) {
        if (exponent & 1 == 1) {
            result *%= value;
        }
        exponent >>= 1;
        value *%= value;
    }
    x.top.* = result;
}

pub fn signextend(int: *Interpreter) !void {
    _ = int;
    // TODO
}
