const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

/// EVM opcodes.
pub const Opcode = enum(u8) {
    STOP = 0x00,

    ADD = 0x01,
    MUL = 0x02,
    SUB = 0x03,
    DIV = 0x04,
    SDIV = 0x05,
    MOD = 0x06,
    SMOD = 0x07,
    ADDMOD = 0x08,
    MULMOD = 0x09,
    EXP = 0x0A,
    SIGNEXTEND = 0x0B,

    // 0x0C
    // 0x0D
    // 0x0E
    // 0x0F

    LT = 0x10,
    GT = 0x11,
    SLT = 0x12,
    SGT = 0x13,
    EQ = 0x14,
    ISZERO = 0x15,
    AND = 0x16,
    OR = 0x17,
    XOR = 0x18,
    NOT = 0x19,
    BYTE = 0x1A,
    SHL = 0x1B,
    SHR = 0x1C,
    SAR = 0x1D,

    // 0x1E
    // 0x1F

    KECCAK256 = 0x20,

    // 0x21
    // 0x22
    // 0x23
    // 0x24
    // 0x25
    // 0x26
    // 0x27
    // 0x28
    // 0x29
    // 0x2A
    // 0x2B
    // 0x2C
    // 0x2D
    // 0x2E
    // 0x2F

    ADDRESS = 0x30,
    BALANCE = 0x31,
    ORIGIN = 0x32,
    CALLER = 0x33,
    CALLVALUE = 0x34,
    CALLDATALOAD = 0x35,
    CALLDATASIZE = 0x36,
    CALLDATACOPY = 0x37,
    CODESIZE = 0x38,
    CODECOPY = 0x39,
    GASPRICE = 0x3A,
    EXTCODESIZE = 0x3B,
    EXTCODECOPY = 0x3C,
    RETURNDATASIZE = 0x3D,
    RETURNDATACOPY = 0x3E,
    EXTCODEHASH = 0x3F,

    BLOCKHASH = 0x40,
    COINBASE = 0x41,
    TIMESTAMP = 0x42,
    NUMBER = 0x43,
    DIFFICULTY = 0x44,
    GASLIMIT = 0x45,
    CHAINID = 0x46,
    SELFBALANCE = 0x47,
    BASEFEE = 0x48,
    BLOBHASH = 0x49,
    BLOBBASEFEE = 0x4A,

    // 0x4B
    // 0x4C
    // 0x4D
    // 0x4E
    // 0x4F

    POP = 0x50,
    MLOAD = 0x51,
    MSTORE = 0x52,
    MSTORE8 = 0x53,
    SLOAD = 0x54,
    SSTORE = 0x55,
    JUMP = 0x56,
    JUMPI = 0x57,
    PC = 0x58,
    MSIZE = 0x59,
    GAS = 0x5A,
    JUMPDEST = 0x5B,
    TSTORE = 0x5C,
    TLOAD = 0x5D,
    MCOPY = 0x5E,

    PUSH0 = 0x5F,
    PUSH1 = 0x60,
    PUSH2 = 0x61,
    PUSH3 = 0x62,
    PUSH4 = 0x63,
    PUSH5 = 0x64,
    PUSH6 = 0x65,
    PUSH7 = 0x66,
    PUSH8 = 0x67,
    PUSH9 = 0x68,
    PUSH10 = 0x69,
    PUSH11 = 0x6A,
    PUSH12 = 0x6B,
    PUSH13 = 0x6C,
    PUSH14 = 0x6D,
    PUSH15 = 0x6E,
    PUSH16 = 0x6F,
    PUSH17 = 0x70,
    PUSH18 = 0x71,
    PUSH19 = 0x72,
    PUSH20 = 0x73,
    PUSH21 = 0x74,
    PUSH22 = 0x75,
    PUSH23 = 0x76,
    PUSH24 = 0x77,
    PUSH25 = 0x78,
    PUSH26 = 0x79,
    PUSH27 = 0x7A,
    PUSH28 = 0x7B,
    PUSH29 = 0x7C,
    PUSH30 = 0x7D,
    PUSH31 = 0x7E,
    PUSH32 = 0x7F,

    DUP1 = 0x80,
    DUP2 = 0x81,
    DUP3 = 0x82,
    DUP4 = 0x83,
    DUP5 = 0x84,
    DUP6 = 0x85,
    DUP7 = 0x86,
    DUP8 = 0x87,
    DUP9 = 0x88,
    DUP10 = 0x89,
    DUP11 = 0x8A,
    DUP12 = 0x8B,
    DUP13 = 0x8C,
    DUP14 = 0x8D,
    DUP15 = 0x8E,
    DUP16 = 0x8F,

    SWAP1 = 0x90,
    SWAP2 = 0x91,
    SWAP3 = 0x92,
    SWAP4 = 0x93,
    SWAP5 = 0x94,
    SWAP6 = 0x95,
    SWAP7 = 0x96,
    SWAP8 = 0x97,
    SWAP9 = 0x98,
    SWAP10 = 0x99,
    SWAP11 = 0x9A,
    SWAP12 = 0x9B,
    SWAP13 = 0x9C,
    SWAP14 = 0x9D,
    SWAP15 = 0x9E,
    SWAP16 = 0x9F,

    LOG0 = 0xA0,
    LOG1 = 0xA1,
    LOG2 = 0xA2,
    LOG3 = 0xA3,
    LOG4 = 0xA4,

    // 0xA5
    // 0xA6
    // 0xA7
    // 0xA8
    // 0xA9
    // 0xAA
    // 0xAB
    // 0xAC
    // 0xAD
    // 0xAE
    // 0xAF
    // 0xB0
    // 0xB1
    // 0xB2
    // 0xB3
    // 0xB4
    // 0xB5
    // 0xB6
    // 0xB7
    // 0xB8
    // 0xB9
    // 0xBA
    // 0xBB
    // 0xBC
    // 0xBD
    // 0xBE
    // 0xBF
    // 0xC0
    // 0xC1
    // 0xC2
    // 0xC3
    // 0xC4
    // 0xC5
    // 0xC6
    // 0xC7
    // 0xC8
    // 0xC9
    // 0xCA
    // 0xCB
    // 0xCC
    // 0xCD
    // 0xCE
    // 0xCF

    DATALOAD = 0xD0,
    DATALOADN = 0xD1,
    DATASIZE = 0xD2,
    DATACOPY = 0xD3,
    // 0xD4
    // 0xD5
    // 0xD6
    // 0xD7
    // 0xD8
    // 0xD9
    // 0xDA
    // 0xDB
    // 0xDC
    // 0xDD
    // 0xDE
    // 0xDF

    RJUMP = 0xE0,
    RJUMPI = 0xE1,
    RJUMPV = 0xE2,
    CALLF = 0xE3,
    RETF = 0xE4,
    JUMPF = 0xE5,

    DUPN = 0xE6,
    SWAPN = 0xE7,
    EXCHANGE = 0xE8,
    // 0xE9
    // 0xEA
    // 0xEB

    CREATE3 = 0xEC,
    CREATE4 = 0xED,
    RETURNCONTRACT = 0xEE,
    // 0xEF

    CREATE = 0xF0,
    CALL = 0xF1,
    CALLCODE = 0xF2,
    RETURN = 0xF3,
    DELEGATECALL = 0xF4,
    CREATE2 = 0xF5,
    // 0xF6
    RETURNDATALOAD = 0xF7,

    EXTCALL = 0xF8,
    EXFCALL = 0xF9,
    STATICCALL = 0xFA,
    EXTSCALL = 0xFB,
    // 0xFC

    REVERT = 0xFD,
    INVALID = 0xFE,
    SELFDESTRUCT = 0xFF,
    _,

    /// Maps each opcode to its name.
    pub const names: [256]?[]const u8 = init: {
        var map = [_]?[]const u8{null} ** 256;
        for (@typeInfo(Opcode).Enum.fields) |variant| {
            map[variant.value] = variant.name;
        }
        break :init map;
    };

    /// Returns whether `value` is a valid opcode.
    pub fn isValid(value: u8) bool {
        return Opcode.names[value] != null;
    }

    /// Returns the name of this opcode.
    pub fn name(self: Opcode) []const u8 {
        return Opcode.names[@intFromEnum(self)].?;
    }

    /// Returns the number of bytes of this push opcode, or `null`.
    pub fn isPush(self: Opcode) ?u8 {
        const p0: u8 = @intFromEnum(Opcode.PUSH0);
        const p32: u8 = @intFromEnum(Opcode.PUSH32);
        const this: u8 = @intFromEnum(self);
        return switch (this) {
            p0...p32 => this - p0,
            else => null,
        };
    }
};

test "opcode maps" {
    for (Opcode.names, 0..) |name, i| {
        const is_valid = name != null;
        try expectEqual(Opcode.isValid(@intCast(i)), is_valid);
        if (is_valid) {
            try expect(std.mem.eql(u8, Opcode.name(@enumFromInt(i)), name.?));
        }
    }
}

test "opcode isPush" {
    try expectEqual(Opcode.MCOPY.isPush(), null);
    try expectEqual(Opcode.PUSH0.isPush().?, 0);
    try expectEqual(Opcode.PUSH1.isPush().?, 1);
    try expectEqual(Opcode.PUSH2.isPush().?, 2);
    try expectEqual(Opcode.PUSH3.isPush().?, 3);
    try expectEqual(Opcode.PUSH4.isPush().?, 4);
    try expectEqual(Opcode.PUSH5.isPush().?, 5);
    try expectEqual(Opcode.PUSH6.isPush().?, 6);
    try expectEqual(Opcode.PUSH7.isPush().?, 7);
    try expectEqual(Opcode.PUSH8.isPush().?, 8);
    try expectEqual(Opcode.PUSH9.isPush().?, 9);
    try expectEqual(Opcode.PUSH10.isPush().?, 10);
    try expectEqual(Opcode.PUSH11.isPush().?, 11);
    try expectEqual(Opcode.PUSH12.isPush().?, 12);
    try expectEqual(Opcode.PUSH13.isPush().?, 13);
    try expectEqual(Opcode.PUSH14.isPush().?, 14);
    try expectEqual(Opcode.PUSH15.isPush().?, 15);
    try expectEqual(Opcode.PUSH16.isPush().?, 16);
    try expectEqual(Opcode.PUSH17.isPush().?, 17);
    try expectEqual(Opcode.PUSH18.isPush().?, 18);
    try expectEqual(Opcode.PUSH19.isPush().?, 19);
    try expectEqual(Opcode.PUSH20.isPush().?, 20);
    try expectEqual(Opcode.PUSH21.isPush().?, 21);
    try expectEqual(Opcode.PUSH22.isPush().?, 22);
    try expectEqual(Opcode.PUSH23.isPush().?, 23);
    try expectEqual(Opcode.PUSH24.isPush().?, 24);
    try expectEqual(Opcode.PUSH25.isPush().?, 25);
    try expectEqual(Opcode.PUSH26.isPush().?, 26);
    try expectEqual(Opcode.PUSH27.isPush().?, 27);
    try expectEqual(Opcode.PUSH28.isPush().?, 28);
    try expectEqual(Opcode.PUSH29.isPush().?, 29);
    try expectEqual(Opcode.PUSH30.isPush().?, 30);
    try expectEqual(Opcode.PUSH31.isPush().?, 31);
    try expectEqual(Opcode.PUSH32.isPush().?, 32);
    try expectEqual(Opcode.DUP1.isPush(), null);
}
