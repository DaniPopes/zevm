const std = @import("std");
const expectEqualSlices = std.testing.expectEqualSlices;

const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;

pub const KECCAK_EMPTY: [32]u8 = decodeHex(32, "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470".*);

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

pub fn decodeHex(comptime n: comptime_int, comptime input: [n * 2]u8) [n]u8 {
    var out: [n]u8 = undefined;
    _ = std.fmt.hexToBytes(&out, &input) catch @panic("invalid hex");
    return out;
}

test "keccak256 empty" {
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha3.Keccak256.hash(&[_]u8{}, &hash, .{});
    try expectEqualSlices(u8, KECCAK_EMPTY[0..], hash[0..]);
}
