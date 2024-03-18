const std = @import("std");

const Interpreter = @import("./Interpreter.zig");
const InstructionPtr = Interpreter.InstructionPtr;
const Opcode = Interpreter.Opcode;

/// The instruction lookup table.
pub const TABLE: [256]InstructionPtr = init: {
    const arithmetic = @import("instructions/arithmetic.zig");
    const bitwise = @import("instructions/bitwise.zig");
    const comparison = @import("instructions/comparison.zig");
    const control = @import("instructions/control.zig");
    const hash = @import("instructions/hash.zig");
    const memory = @import("instructions/memory.zig");
    const stack = @import("instructions/stack.zig");

    var map: [256]InstructionPtr = undefined;
    // TODO: remaining instructions
    for (0..256) |i| {
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

            .KECCAK256 => hash.keccak256,

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
            // .BLOBHASH = todo.blobhash,
            // .BLOBBASEFEE = todo.blobbasefee,

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

            .PUSH0 => stack.push0,
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

            // .DATALOAD => todo.dataload,
            // .DATALOADN => todo.dataloadn,
            // .DATASIZE => todo.datasize,
            // .DATACOPY => todo.datacopy,

            // .RJUMP => todo.rjump,
            // .RJUMPI => todo.rjumpi,
            // .RJUMPV => todo.rjumpv,
            // .CALLF => todo.callf,
            // .RETF => todo.retf,
            // .JUMPF => todo.jumpf,

            .DUPN => stack.dupn,
            .SWAPN => stack.swapn,
            .EXCHANGE => stack.exchange,

            // .CREATE3 => todo.create3,
            // .CREATE4 => todo.create4,
            // .RETURNCONTRACT => todo.returncontract,

            // .CREATE => todo.create,
            // .CALL => todo.call,
            // .CALLCODE => todo.callcode,
            .RETURN => control.ret,
            // .DELEGATECALL => todo.delegatecall,
            // .CREATE2 => todo.create2,
            // .RETURNDATALOAD => todo.returndataload,

            // .EXTCALL => todo.extcall,
            // .EXFCALL => todo.exfcall,
            // .STATICCALL => todo.staticcall,
            // .EXTSCALL => todo.extscall,

            .REVERT => control.revert,
            .INVALID => control.invalid,
            // .SELFDESTRUCT => todo.selfdestruct,

            else => control.notFound,
        };
    }
    break :init map;
};

test {
    std.testing.refAllDecls(@This());
}
