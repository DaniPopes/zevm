const std = @import("std");

const utils = @import("utils.zig");
const interpreter = @import("../interpreter.zig");
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

pub fn keccak256(int: *Interpreter) !void {
    const offset_, const len_ = try int.stack.popn(2);
    const offset = try utils.castInt(usize, offset_);
    const len = try utils.castInt(usize, len_);
    var hash: [32]u8 = undefined;
    if (len == 0) {
        hash = utils.KECCAK_EMPTY;
    } else {
        try int.memResize(offset, len);
        const input = int.memory.getSlice(offset, len);
        std.crypto.hash.sha3.Keccak256.hash(input, &hash, .{});
    }
    return int.stack.pushBeBytes(hash);
}
