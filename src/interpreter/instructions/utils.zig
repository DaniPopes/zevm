const std = @import("std");

const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;

pub fn cast_int(comptime T: type, x: u256) !T {
    if (x > std.math.maxInt(T)) {
        return InstructionResult.InvalidOperandOOG;
    }
    return @intCast(x);
}

pub fn cast_saturate(comptime T: type, x: u256) T {
    if (x > std.math.maxInt(T)) {
        return std.math.maxInt(T);
    }
    return @intCast(x);
}
