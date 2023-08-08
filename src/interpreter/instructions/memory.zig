const std = @import("std");

const interpreter = @import("../interpreter.zig");
const utils = @import("utils.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn mload(int: *Interpreter) !void {
    var offset = try utils.castInt(usize, try int.stack.pop());
    try int.memResize(offset, 32);
    return int.stack.pushBeBytes(int.memory.getArray(offset, 32).*);
}

pub fn mstore(int: *Interpreter) !void {
    var x = try int.stack.popn(2);
    var offset = try utils.castInt(usize, x[0]);
    try int.memResize(offset, 32);
    int.memory.setU256(offset, &x[1]);
}

pub fn mstore8(int: *Interpreter) !void {
    var x = try int.stack.popn(2);
    var offset = try utils.castInt(usize, x[0]);
    try int.memResize(offset, 1);
    int.memory.setByte(offset, @intCast(x[1] & 0xff));
}

pub fn msize(int: *Interpreter) !void {
    return int.stack.push(int.memory.len);
}

pub fn mcopy(int: *Interpreter) !void {
    var x = try int.stack.popn(3);
    var len = try utils.castInt(usize, x[2]);
    if (len == 0) return;

    var dst = try utils.castInt(usize, x[0]);
    var src = try utils.castInt(usize, x[1]);
    try int.memResize(@max(dst, src), len);
    int.memory.copy(dst, src, len);
}
