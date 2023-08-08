const std = @import("std");
const little_endian = @import("builtin").cpu.arch.endian() == .Little;

const interpreter = @import("../interpreter.zig");
const utils = @import("utils.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn bitand(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value & x.top.*;
}

pub fn bitor(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value | x.top.*;
}

pub fn bitxor(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value ^ x.top.*;
}

pub fn bitnot(int: *Interpreter) !void {
    var top = try int.stack.top();
    top.* = ~top.*;
}

pub fn byte(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    var byte_idx = utils.castSaturate(usize, x.value);
    if (byte_idx < 32) {
        var bytes = @as(*[32]u8, @ptrCast(x.top));
        // `byte` uses big-endian
        if (little_endian) {
            byte_idx = 31 - byte_idx;
        }
        x.top.* = bytes[byte_idx];
    } else {
        x.top.* = 0;
    }
}

pub fn shl(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    if (x.top.* < 256) {
        x.top.* = x.value << @as(u8, @intCast(x.top.*));
    } else {
        x.top.* = 0;
    }
}

pub fn shr(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    if (x.top.* < 256) {
        x.top.* = x.value >> @as(u8, @intCast(x.top.*));
    } else {
        x.top.* = 0;
    }
}

pub fn sar(int: *Interpreter) !void {
    _ = int;
    // TODO
}
