const std = @import("std");
const expectEqualSlices = std.testing.expectEqualSlices;

const Interpreter = @import("../Interpreter.zig");
const InstructionResult = Interpreter.InstructionResult;

pub const KECCAK_EMPTY: [32]u8 = decodeHex("c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");

pub fn castInt(comptime T: type, x: u256) !T {
    if (x > std.math.maxInt(T)) return InstructionResult.InvalidOperandOOG;
    return @intCast(x);
}

pub fn castSaturate(comptime T: type, x: u256) T {
    if (x > std.math.maxInt(T)) return std.math.maxInt(T);
    return @intCast(x);
}

pub inline fn decodeHex(comptime input: []const u8) [hexLength(input)]u8 {
    comptime {
        const inp = if (hasHaxPrefix(input)) input[2..] else input;
        var out: [hexLength(input)]u8 = undefined;
        _ = std.fmt.hexToBytes(&out, inp) catch |e| @compileError("invalid hex: " ++ @errorName(e));
        return out;
    }
}

fn hexLength(comptime input: []const u8) usize {
    var len = input.len;
    if (hasHaxPrefix(input)) len -= 2;
    return len / 2;
}

fn hasHaxPrefix(input: []const u8) bool {
    return (input.len >= 2 and input[0] == '0' and input[1] == 'x');
}

test decodeHex {
    try expectEqualSlices(u8, &decodeHex("deadbeef"), &[4]u8{ 0xde, 0xad, 0xbe, 0xef });
    try expectEqualSlices(u8, &decodeHex("0xDeAdBeEf"), &[4]u8{ 0xde, 0xad, 0xbe, 0xef });
}

test "keccak256 empty" {
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha3.Keccak256.hash(&[_]u8{}, &hash, .{});
    try expectEqualSlices(u8, &KECCAK_EMPTY, &hash);
}
