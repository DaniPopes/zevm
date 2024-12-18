//! EVM bytecode interpreter.

const std = @import("std");
const debug = std.log.debug;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const evmc = @import("evmc");

const instructions = @import("instructions.zig");
const utils = @import("utils.zig");
pub const InstructionResult = @import("result.zig").InstructionResult;
pub const Memory = @import("Memory.zig");
pub const Opcode = @import("opcode.zig").Opcode;
pub const Stack = @import("Stack.zig");
pub const gas = @import("gas.zig");
pub const Gas = gas.Gas;
const Host = @import("../vm/Vm.zig").Host;
const Rev = @import("../rev.zig").Rev;

/// The instruction function type.
pub const Instruction = fn (*Self) InstructionResult!void;
/// The instruction function pointer type.
pub const InstructionPtr = *const Instruction;

/// The current instruction pointer. This always points into `bytecode`.
ip: [*]const u8,
/// The gas state.
gas: Gas,
/// The EVM revision.
rev: Rev,
/// The host.
host: Host,
/// The memory.
memory: Memory,
/// The bytecode slice.
bytecode: []const u8,
/// The offset into `memory` of the return data.
///
/// This value must be ignored if `return_len` is 0.
return_offset: usize,
/// The length of the return data.
return_len: usize,
/// The stack.
stack: Stack,

const Self = @This();

/// Creates a new interpreter. Only allocates the memory. Use `reset` to initialize.
pub fn init(allocator: Allocator) !Self {
    return .{
        .bytecode = undefined,
        .ip = undefined,
        .gas = undefined,
        .stack = undefined,
        .memory = try Memory.init(allocator),
        .return_offset = undefined,
        .return_len = undefined,
        .rev = undefined,
        .host = undefined,
    };
}

pub fn deinit(self: *Self) void {
    self.memory.deinit();
}

pub fn reset(self: *Self, msg: *const evmc.evmc_message, rev: Rev, host: Host, code: []const u8) void {
    self.bytecode = code;
    self.ip = code.ptr;
    self.gas = Gas.init(@intCast(msg.gas));
    self.stack.clear();
    self.memory.clear();
    self.return_offset = 0;
    self.return_len = 0;
    self.rev = rev;
    self.host = host;
}

/// Returns the allocator.
pub fn getAllocator(self: *Self) Allocator {
    return self.memory.inner.allocator;
}

/// Returns the current EVM revision.
pub inline fn revision(self: *Self) Rev {
    return self.rev;
}

/// Returns the current program counter.
pub fn pc(self: *Self) usize {
    return @intFromPtr(self.ip) - @intFromPtr(self.bytecode.ptr);
}

/// Runs the instruction loop until completion.
pub fn run(self: *Self) InstructionResult {
    debug("rev: {s}", .{@tagName(self.revision())});

    var c: usize = 0;
    const res = while (true) {
        if (c > 10000) {
            std.log.warn("execution taking too long, breaking", .{});
            break InstructionResult.OutOfGas;
        }
        c += 1;
        self.step() catch |e| break e;
    };
    debug("Executed {} instructions, result: {}", .{ c, res });
    return res;
}

/// Evaluates the instruction located at the current instruction pointer.
/// Increments the instruction pointer by at least one, depending on the evaluated instruction.
pub fn step(self: *Self) !void {
    const opcode = try self.nextByte();
    if (std.log.defaultLogEnabled(.debug)) {
        var as_enum = @as(Opcode, @enumFromInt(opcode));

        var data_: []const u8 = &[0]u8{};
        if (as_enum.isPush()) |n| data_ = self.ip[0..n];
        const data = std.fmt.fmtSliceHexLower(data_);

        debug("{: >4}: 0x{X:0>2} {s} {}", .{ self.pc(), opcode, @tagName(as_enum), data });
    }
    return instructions.TABLE[opcode](self);
}

/// Reads one byte from the bytecode.
pub inline fn readByte(self: *Self) !u8 {
    return (try self.readBytes(1))[0];
}

/// Reads `n` bytes from the bytecode.
pub inline fn readBytes(self: *Self, n: usize) ![*]const u8 {
    if (!self.inBounds(self.ip + n)) return InstructionResult.OutOfOffset;
    return self.ip[0..n];
}

/// Reads the next byte, advancing the instruction pointer if successful.
pub inline fn nextByte(self: *Self) !u8 {
    return (try self.nextBytes(1))[0];
}

/// Reads the next `n` bytes, advancing the instruction pointer if successful.
pub inline fn nextBytes(self: *Self, n: usize) ![*]const u8 {
    const bytes = try self.readBytes(n);
    self.ip += n;
    return bytes;
}

/// Checks if the instruction pointer is in bounds of `bytecode`.
pub inline fn inBounds(self: *Self, iptr: [*]const u8) bool {
    const ip = @intFromPtr(iptr);
    const start = @intFromPtr(self.bytecode.ptr);
    return ip >= start and ip <= start + self.bytecode.len;
}

/// Returns `true` if the given pointer is a valid jump destination.
pub inline fn isValidJump(self: *Self, iptr: [*]const u8) bool {
    return self.inBounds(iptr) and iptr[0] == @intFromEnum(Opcode.JUMPDEST);
}

/// Returns the slice of the return value.
pub fn returnValue(self: *Self) []u8 {
    if (self.return_len == 0) return &[0]u8{};
    return self.memory.getSlice(self.return_offset, self.return_len);
}

/// Resizes the memory to `offset + len`, recording a memory expansion cost if necessary.
pub inline fn resizeMemory(self: *Self, offset: usize, len: usize) !void {
    const new_len, const overflow = @addWithOverflow(offset, len);
    if (overflow != 0) return InstructionResult.MemoryOOG;
    if (new_len <= self.memory.len()) return;
    const rounded_size = next32(new_len);
    // TODO: memory limit
    const num_words = rounded_size / 32;
    if (!self.gas.recordMemory(num_words)) return InstructionResult.MemoryOOG;
    self.memory.resize(rounded_size) catch @panic("OOM");
}

/// Records a gas cost.
pub inline fn recordGas(self: *Self, cost: u64) !void {
    if (!self.gas.recordCost(cost)) return InstructionResult.OutOfGas;
}

/// Records a gas cost.
pub inline fn recordGasOpt(self: *Self, cost: ?u64) !void {
    return if (cost) |g| self.recordGas(g) else InstructionResult.OutOfGas;
}

pub fn dumpReturnValue(self: *Self) void {
    if (self.return_len == 0) return;
    debug("Return value:", .{});
    utils.dumpSlice(self.returnValue());
}

fn next32(x: usize) usize {
    return switch (x % 32) {
        0 => x,
        else => |y| x +| (32 - y),
    };
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

test next32 {
    try expectEqual(next32(0), 0);
    try expectEqual(next32(1), 32);
    try expectEqual(next32(2), 32);
    try expectEqual(next32(31), 32);
    try expectEqual(next32(32), 32);
    try expectEqual(next32(33), 64);
    try expectEqual(next32(std.math.maxInt(usize)), std.math.maxInt(usize));
}
