const std = @import("std");

pub const interpreter = @import("interpreter/interpreter.zig");
const Opcode = interpreter.Opcode;

const std_options = struct {
    pub const log_level = .debug;
};

pub fn main() !void {
    const bytecode = [_]u8{
        op(.PUSH1),
        0x01,
        op(.PUSH1),
        0x02,
        op(.ADD),
        op(.STOP),
    };
    var int = try interpreter.Interpreter.init(bytecode[0..], std.heap.c_allocator);
    defer int.deinit();
    _ = int.run() catch {};
    int.dumpReturnValue();
    int.stack.dump();
    int.memory.dump();
}

fn op(opcode: Opcode) u8 {
    return @intFromEnum(opcode);
}

test {
    std.testing.refAllDecls(@This());
}
