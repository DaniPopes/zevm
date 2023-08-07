const std = @import("std");

const interpreter = @import("root").interpreter;
const Instruction = interpreter.Instruction;
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn add(int: *Interpreter) !void {
    var x = try int.stack.popTop();
    x.top.* = x.value +% x.top.*;
}
