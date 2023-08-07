const std = @import("std");

const Interpreter = @import("interpreter.zig").Interpreter;

const std_options = struct {
    pub const log_level = .debug;
};

pub fn main() !void {
    const bytecode = [_]u8{0};
    var interpreter = Interpreter.new(bytecode[0..]);
    interpreter.run();
}

test {
    std.testing.refAllDecls(@This());
}
