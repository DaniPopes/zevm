const std = @import("std");
const debug = std.log.debug;
const Allocator = std.mem.Allocator;

const utils = @import("utils.zig");

pub const Stack = @import("stack.zig").Stack;
pub const Memory = @import("memory.zig").Memory;

pub const InstructionResult = @import("result.zig").InstructionResult;
pub const Opcode = @import("opcode.zig").Opcode;

const instructions: [256]Instruction = init: {
    const arithmetic = @import("instructions/arithmetic.zig");
    const bitwise = @import("instructions/bitwise.zig");
    const comparison = @import("instructions/comparison.zig");
    const control = @import("instructions/control.zig");
    const memory = @import("instructions/memory.zig");
    const stack = @import("instructions/stack.zig");

    var map: [256]Instruction = undefined;
    // TODO: remaining instructions
    for (0..255) |i| {
        map[i] = switch (@as(Opcode, @enumFromInt(i))) {
            .STOP => control.stop,
            .ADD => arithmetic.add,
            .MUL => arithmetic.mul,
            .SUB => arithmetic.sub,
            .DIV => arithmetic.div,
            .SDIV => arithmetic.sdiv,
            .MOD => arithmetic.mod,
            .SMOD => arithmetic.smod,
            .ADDMOD => arithmetic.addmod,
            .MULMOD => arithmetic.mulmod,
            .EXP => arithmetic.exp,
            .SIGNEXTEND => arithmetic.signextend,

            .LT => comparison.lt,
            .GT => comparison.gt,
            .SLT => comparison.slt,
            .SGT => comparison.sgt,
            .EQ => comparison.eq,
            .ISZERO => comparison.iszero,
            .AND => bitwise.bitand,
            .OR => bitwise.bitor,
            .XOR => bitwise.bitxor,
            .NOT => bitwise.bitnot,
            .BYTE => bitwise.byte,
            .SHL => bitwise.shl,
            .SHR => bitwise.shr,
            .SAR => bitwise.sar,

            // .KECCAK256 => todo.keccak256,

            // .ADDRESS => todo.address,
            // .BALANCE => todo.balance,
            // .ORIGIN => todo.origin,
            // .CALLER => todo.caller,
            // .CALLVALUE => todo.callvalue,
            // .CALLDATALOAD => todo.calldataload,
            // .CALLDATASIZE => todo.calldatasize,
            // .CALLDATACOPY => todo.calldatacopy,
            // .CODESIZE => todo.codesize,
            // .CODECOPY => todo.codecopy,
            // .GASPRICE => todo.gasprice,
            // .EXTCODESIZE => todo.extcodesize,
            // .EXTCODECOPY => todo.extcodecopy,
            // .RETURNDATASIZE => todo.returndatasize,
            // .RETURNDATACOPY => todo.returndatacopy,
            // .EXTCODEHASH => todo.extcodehash,

            // .BLOCKHASH => todo.blockhash,
            // .COINBASE => todo.coinbase,
            // .TIMESTAMP => todo.timestamp,
            // .NUMBER => todo.number,
            // .DIFFICULTY => todo.difficulty,
            // .GASLIMIT => todo.gaslimit,
            // .CHAINID => todo.chainid,
            // .SELFBALANCE => todo.selfbalance,
            // .BASEFEE => todo.basefee,

            .POP => stack.pop,
            .MLOAD => memory.mload,
            .MSTORE => memory.mstore,
            .MSTORE8 => memory.mstore8,
            // .SLOAD => todo.sload,
            // .SSTORE => todo.sstore,
            .JUMP => control.jump,
            .JUMPI => control.jumpi,
            .PC => control.pc,
            .MSIZE => memory.msize,
            // .GAS => todo.gas,
            .JUMPDEST => control.jumpdest,
            // .TSTORE => todo.tstore,
            // .TLOAD => todo.tload,
            .MCOPY => memory.mcopy,

            .PUSH0 => stack.push(0),
            .PUSH1 => stack.push(1),
            .PUSH2 => stack.push(2),
            .PUSH3 => stack.push(3),
            .PUSH4 => stack.push(4),
            .PUSH5 => stack.push(5),
            .PUSH6 => stack.push(6),
            .PUSH7 => stack.push(7),
            .PUSH8 => stack.push(8),
            .PUSH9 => stack.push(9),
            .PUSH10 => stack.push(10),
            .PUSH11 => stack.push(11),
            .PUSH12 => stack.push(12),
            .PUSH13 => stack.push(13),
            .PUSH14 => stack.push(14),
            .PUSH15 => stack.push(15),
            .PUSH16 => stack.push(16),
            .PUSH17 => stack.push(17),
            .PUSH18 => stack.push(18),
            .PUSH19 => stack.push(19),
            .PUSH20 => stack.push(20),
            .PUSH21 => stack.push(21),
            .PUSH22 => stack.push(22),
            .PUSH23 => stack.push(23),
            .PUSH24 => stack.push(24),
            .PUSH25 => stack.push(25),
            .PUSH26 => stack.push(26),
            .PUSH27 => stack.push(27),
            .PUSH28 => stack.push(28),
            .PUSH29 => stack.push(29),
            .PUSH30 => stack.push(30),
            .PUSH31 => stack.push(31),
            .PUSH32 => stack.push(32),

            .DUP1 => stack.dup(1),
            .DUP2 => stack.dup(2),
            .DUP3 => stack.dup(3),
            .DUP4 => stack.dup(4),
            .DUP5 => stack.dup(5),
            .DUP6 => stack.dup(6),
            .DUP7 => stack.dup(7),
            .DUP8 => stack.dup(8),
            .DUP9 => stack.dup(9),
            .DUP10 => stack.dup(10),
            .DUP11 => stack.dup(11),
            .DUP12 => stack.dup(12),
            .DUP13 => stack.dup(13),
            .DUP14 => stack.dup(14),
            .DUP15 => stack.dup(15),
            .DUP16 => stack.dup(16),

            .SWAP1 => stack.swap(1),
            .SWAP2 => stack.swap(2),
            .SWAP3 => stack.swap(3),
            .SWAP4 => stack.swap(4),
            .SWAP5 => stack.swap(5),
            .SWAP6 => stack.swap(6),
            .SWAP7 => stack.swap(7),
            .SWAP8 => stack.swap(8),
            .SWAP9 => stack.swap(9),
            .SWAP10 => stack.swap(10),
            .SWAP11 => stack.swap(11),
            .SWAP12 => stack.swap(12),
            .SWAP13 => stack.swap(13),
            .SWAP14 => stack.swap(14),
            .SWAP15 => stack.swap(15),
            .SWAP16 => stack.swap(16),

            // .LOG0 => todo.log(0),
            // .LOG1 => todo.log(1),
            // .LOG2 => todo.log(2),
            // .LOG3 => todo.log(3),
            // .LOG4 => todo.log(4),

            // .RJUMP => todo.rjump,
            // .RJUMPI => todo.rjumpi,
            // .RJUMPV => todo.rjumpv,
            // .CALLF => todo.callf,
            // .RETF => todo.retf,

            // .DUPN => todo.dupn,
            // .SWAPN => todo.swapn,
            // .DATALOAD => todo.dataload,
            // .DATALOADN => todo.dataloadn,
            // .DATASIZE => todo.datasize,
            // .DATACOPY => todo.datacopy,

            // .CREATE => todo.create,
            // .CALL => todo.call,
            // .CALLCODE => todo.callcode,
            .RETURN => control.ret,
            // .DELEGATECALL => todo.delegatecall,
            // .CREATE2 => todo.create2,
            // .STATICCALL => todo.staticcall,
            .REVERT => control.revert,
            .INVALID => control.invalid,
            // .SELFDESTRUCT => todo.selfdestruct,

            else => control.notFound,
        };
    }
    break :init map;
};

/// The instruction function type.
pub const Instruction = *const fn (*Interpreter) InstructionResult!void;

/// EVM bytecode interpreter.
pub const Interpreter = struct {
    /// The bytecode slice.
    bytecode: []const u8,
    /// The current instruction pointer. This always points into `bytecode`.
    ip: [*]const u8,
    /// The stack.
    stack: Stack,
    /// The memory.
    memory: Memory,
    /// The offset into `memory` of the return data.
    ///
    /// This value must be ignored if `return_len` is 0.
    return_offset: usize,
    /// The length of the return data.
    return_len: usize,

    /// Creates a new interpreter.
    pub fn init(bytecode: []const u8, allocator: Allocator) Allocator.Error!Interpreter {
        return .{
            .bytecode = bytecode,
            .ip = bytecode.ptr,
            .stack = Stack.init(),
            .memory = try Memory.init(allocator),
            .return_offset = 0,
            .return_len = 0,
        };
    }

    pub fn deinit(self: *Interpreter) void {
        self.memory.deinit();
    }

    /// Returns the current program counter.
    pub fn pc(self: *Interpreter) usize {
        return @intFromPtr(self.ip) - @intFromPtr(self.bytecode.ptr);
    }

    /// Runs the instruction loop until completion.
    pub fn run(self: *Interpreter) InstructionResult {
        var c: usize = 0;
        var res = while (true) {
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
    pub fn step(self: *Interpreter) !void {
        var opcode = self.nextByte();
        if (std.log.defaultLogEnabled(.debug)) {
            var as_enum = @as(Opcode, @enumFromInt(opcode));

            var data_: []const u8 = ([0]u8{})[0..];
            if (as_enum.isPush()) |n| data_ = self.ip[0..n];
            var data = std.fmt.fmtSliceHexLower(data_);

            debug("{: >4}: 0x{X:0>2} {s} {}", .{ self.pc(), opcode, @tagName(as_enum), data });
        }
        if (!self.inBounds(null)) return InstructionResult.OutOfOffset;
        return instructions[opcode](self);
    }

    /// Checks if the instruction pointer is in bounds of `bytecode`.
    pub fn inBounds(self: *Interpreter, iptr: ?[*]const u8) bool {
        var ip = @intFromPtr(iptr orelse self.ip);
        var start = @intFromPtr(self.bytecode.ptr);
        return ip >= start and ip <= start + self.bytecode.len;
    }

    /// Returns the slice of the return value.
    pub fn returnValue(self: *Interpreter) []u8 {
        if (self.return_len == 0) return &[0]u8{};
        return self.memory.getSlice(self.return_offset, self.return_len);
    }

    pub fn dumpReturnValue(self: *Interpreter) void {
        if (self.return_len == 0) return;
        debug("Return value:", .{});
        utils.dumpSlice(self.returnValue());
    }

    /// Returns the next byte and advances the instruction pointer by one.
    pub fn nextByte(self: *Interpreter) u8 {
        return self.nextByteSlice(1)[0];
    }

    /// Returns a pointer to the next `n` bytes and advances the instruction pointer by `n`.
    pub fn nextByteSlice(self: *Interpreter, comptime n: usize) *const [n]u8 {
        var value = self.ip[0..n];
        self.ip += n;
        return value;
    }

    pub fn memResize(self: *Interpreter, offset: usize, len: usize) !void {
        var new_len = next32(offset +| len) catch return InstructionResult.MemoryOOG;
        // TODO: memory limit
        if (new_len > self.memory.len) {
            // TODO: gas
            self.memory.resize(new_len) catch @panic("OOM");
        }
    }
};

fn next32(x: usize) !usize {
    var r = x;
    r &= 31;
    r +%= 1;
    r = ~r;
    r &= 31;
    return std.math.add(usize, x, r);
}
