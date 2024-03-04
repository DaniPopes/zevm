const std = @import("std");

const utils = @import("utils.zig");
const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn keccak256(int: *Interpreter) !void {
    const offset_, const len_ = try int.stack.popn(2);
    const len = try utils.castInt(usize, len_);
    try int.recordGasOpt(gas.keccak256Cost(len));
    var hash: [32]u8 = undefined;
    if (len == 0) {
        hash = utils.KECCAK_EMPTY;
    } else {
        const offset = try utils.castInt(usize, offset_);
        try int.resizeMemory(offset, len);
        const input = int.memory.getSlice(offset, len);
        std.crypto.hash.sha3.Keccak256.hash(input, &hash, .{});
    }
    return int.stack.pushBeBytes(hash);
}
