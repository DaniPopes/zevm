const std = @import("std");

pub const interpreter = @import("interpreter/interpreter.zig");
const Op = interpreter.Opcode;

const std_options = struct {
    pub const log_level = .debug;
};

pub fn main() !void {
    const bytecode = [_]u8{
        @intFromEnum(Op.PUSH1),
        0x01,
        @intFromEnum(Op.PUSH1),
        0x02,
        @intFromEnum(Op.ADD),
        @intFromEnum(Op.STOP),
    };
    var int = interpreter.Interpreter.new(bytecode[0..]);
    var ret = int.run();
    std.log.debug("Returned {}", .{ret});
    int.stack.dump();
}

test {
    std.testing.refAllDecls(@This());
}
