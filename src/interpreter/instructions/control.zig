const std = @import("std");

const interpreter = @import("root").interpreter;
const Instruction = interpreter.Instruction;
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn jumpdest(_: *Interpreter) !void {}

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
