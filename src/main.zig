const std = @import("std");

/// EVMC: Ethereum Client-VM Connector API
pub const evmc = @import("evmc");

pub const primitives = @import("primitives.zig");
pub const Interpreter = @import("interpreter/Interpreter.zig");
pub const Rev = @import("rev.zig").Rev;
const Opcode = Interpreter.Opcode;

pub const Vm = @import("vm/Vm.zig");

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

    var host = try Vm.Host.dummy(allocator);
    defer host.deinit();
    var vm = try Vm.init(allocator);
    defer vm.deinit();
    const msg = evmc.evmc_message{
        .kind = evmc.EVMC_CALL,
        // .flags = evmc.EVMC_STATIC,
        .depth = 0,
        .gas = 1000,
        // .recipient = ,
        // .sender = ,
        // .input_data = ,
        // .input_size = ,
        // .value = ,
        // .create2_salt = ,
        // .code_address = ,
        .code = bytecode.ptr,
        .code_size = bytecode.len,
    };
    const result = vm.execute(host.host(), Rev.latest, &msg, bytecode);
    std.log.debug("result: {}", .{result});
    vm.frames.items[0].interpreter.dumpReturnValue();
    vm.frames.items[0].interpreter.stack.dump();
    vm.frames.items[0].interpreter.memory.dump();
}

fn op(opcode: Opcode) u8 {
    return @intFromEnum(opcode);
}

test {
    // Can't be recursive because of "dependency loop detected" in `evmc` bindings.
    std.testing.refAllDecls(@This());
}
