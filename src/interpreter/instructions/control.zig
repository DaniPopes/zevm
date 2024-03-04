const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;
const Opcode = @import("../opcode.zig").Opcode;
const utils = @import("utils.zig");

pub fn jump(int: *Interpreter) !void {
    try int.recordGas(gas.mid);
    const dst = try int.stack.pop();
    return doJump(int, dst);
}

pub fn jumpi(int: *Interpreter) !void {
    try int.recordGas(gas.high);
    const dst, const cond = try int.stack.popn(2);
    if (cond != 0) return doJump(int, dst);
}

fn doJump(int: *Interpreter, dst_: u256) !void {
    const dst = try utils.castInt(usize, dst_);
    const dst_ptr: [*]const u8 = int.bytecode.ptr + dst;
    if (!int.isValidJump(dst_ptr)) return InstructionResult.InvalidJump;
    int.ip = dst_ptr;
}

pub fn jumpdest(int: *Interpreter) !void {
    return int.recordGas(gas.jumpdest);
}

pub fn ret(int: *Interpreter) !void {
    try doReturn(int);
    return InstructionResult.Return;
}

pub fn revert(int: *Interpreter) !void {
    try doReturn(int);
    return InstructionResult.Revert;
}

fn doReturn(int: *Interpreter) !void {
    const offset_, const len_ = try int.stack.popn(2);
    const len = try utils.castInt(usize, len_);
    if (len != 0) {
        const offset = try utils.castInt(usize, offset_);
        try int.resizeMemory(offset, len);
        int.return_offset = offset;
    }
    int.return_len = len;
}

pub fn pc(int: *Interpreter) !void {
    try int.recordGas(gas.base);
    // - 1 because we have already advanced the instruction pointer in `Interpreter.step`
    return int.stack.push(int.pc() - 1);
}

pub fn stop(_: *Interpreter) !void {
    return InstructionResult.Stop;
}

pub fn invalid(_: *Interpreter) !void {
    return InstructionResult.InvalidFEOpcode;
}

pub fn notFound(_: *Interpreter) !void {
    return InstructionResult.OpcodeNotFound;
}
