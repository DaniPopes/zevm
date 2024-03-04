const std = @import("std");

pub const Interpreter = @import("interpreter/Interpreter.zig");
pub const Rev = @import("rev.zig").Rev;
const Opcode = Interpreter.Opcode;

/// EVMC: Ethereum Client-VM Connector API
pub const evmc = @import("evmc");

const std_options = struct {
    pub const log_level = .debug;
};

const DEFAULT_BYTECODE: []const u8 = &[_]u8{
    op(.PUSH1),
    0x01,
    op(.PUSH1),
    0x02,
    op(.ADD),
    op(.STOP),
};

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var bytecode: []const u8 = undefined;
    if (args.len >= 2) {
        const arg = args[1];
        var hex: []u8 = undefined;
        if (std.mem.startsWith(u8, arg, "0x")) {
            hex = arg[2..];
        } else {
            const file = try std.fs.cwd().openFile(arg, .{});
            hex = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        }
        bytecode = try allocator.alloc(u8, hex.len / 2);
        bytecode = try std.fmt.hexToBytes(@constCast(bytecode), hex);
    } else {
        bytecode = DEFAULT_BYTECODE;
    }

    var int = try Interpreter.init(allocator, bytecode, 100);
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
