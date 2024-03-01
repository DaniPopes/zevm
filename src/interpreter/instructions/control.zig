const std = @import("std");

const interpreter = @import("../interpreter.zig");
const utils = @import("utils.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn jump(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn jumpi(int: *Interpreter) !void {
    _ = int;
    // TODO
}

pub fn jumpdest(int: *Interpreter) !void {
    _ = int;
    // TODO: Gas
}

fn return_setup(int: *Interpreter) !void {
    // [0]: offset, [1]: len
    const x = try int.stack.popn(2);
    const len = try utils.castInt(usize, x[1]);
    if (len != 0) {
        const offset = try utils.castInt(usize, x[0]);
        try int.memResize(offset, len);
        int.return_offset = offset;
    }
    int.return_len = len;
}

pub fn ret(int: *Interpreter) !void {
    try return_setup(int);
    return InstructionResult.Return;
}

pub fn revert(int: *Interpreter) !void {
    try return_setup(int);
    return InstructionResult.Revert;
}

pub fn pc(int: *Interpreter) !void {
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
