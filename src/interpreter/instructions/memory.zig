const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const utils = @import("utils.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn mload(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const offset = try utils.castInt(usize, try int.stack.pop());
    try int.resizeMemory(offset, 32);
    return int.stack.pushBeBytes(int.memory.getArray(offset, 32).*);
}

pub fn mstore(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const offset_, const value = try int.stack.popn(2);
    const offset = try utils.castInt(usize, offset_);
    try int.resizeMemory(offset, 32);
    int.memory.setU256(offset, value);
}

pub fn mstore8(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const offset_, const value = try int.stack.popn(2);
    const offset = try utils.castInt(usize, offset_);
    try int.resizeMemory(offset, 1);
    int.memory.setByte(offset, @intCast(value & 0xff));
}

pub fn msize(int: *Interpreter) !void {
    try int.recordGas(gas.base);
    return int.stack.push(int.memory.len());
}

pub fn mcopy(int: *Interpreter) !void {
    const dst_, const src_, const len_ = try int.stack.popn(3);
    const len = try utils.castInt(usize, len_);
    try int.recordGasOpt(gas.copyCost(len));
    if (len == 0) return;

    const dst = try utils.castInt(usize, dst_);
    const src = try utils.castInt(usize, src_);
    try int.resizeMemory(@max(dst, src), len);
    int.memory.copy(dst, src, len);
}
