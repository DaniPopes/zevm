const std = @import("std");

const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;

pub fn castInt(comptime T: type, x: u256) !T {
    if (x > std.math.maxInt(T)) {
        return InstructionResult.InvalidOperandOOG;
    }
    return @intCast(x);
}

pub fn castSaturate(comptime T: type, x: u256) T {
    if (x > std.math.maxInt(T)) {
        return std.math.maxInt(T);
    }
    return @intCast(x);
}
