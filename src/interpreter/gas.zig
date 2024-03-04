//! Gas cost constants and functions.

const std = @import("std");
const expectEqual = std.testing.expectEqual;

const Rev = @import("../rev.zig").Rev;

// Taken directly from the [Yellow Paper Appending G](https://ethereum.github.io/yellowpaper/paper.pdf).

/// Nothing paid for operations of the set `W_zero`.
pub const zero: u64 = 0;
/// Amount of gas to pay for a `JUMPDEST` operation.
pub const jumpdest: u64 = 1;
/// Amount of gas to pay for operations of the set `W_base`.
pub const base: u64 = 2;
/// Amount of gas to pay for operations of the set `W_verylow`.
pub const verylow: u64 = 3;
/// Amount of gas to pay for operations of the set `W_low`.
pub const low: u64 = 5;
/// Amount of gas to pay for operations of the set `W_mid`.
pub const mid: u64 = 8;
/// Amount of gas to pay for operations of the set `W_high`.
pub const high: u64 = 10;
/// Cost of a warm account or storage access.
pub const warmaccess: u64 = 100;
/// Cost of warming up an account with the access list.
pub const accesslistaddress: u64 = 2400;
/// Cost of warming up a storage with the access list.
pub const accessliststorage: u64 = 1900;
/// Cost of a cold account access.
pub const coldaccountaccess: u64 = 2600;
/// Cost of a cold storage access.
pub const coldsload: u64 = 2100;
/// Paid for an `SSTORE` operation when the storage value is set to non-zero from zero.
pub const sset: u64 = 20000;
/// Paid for an `SSTORE` operation when the storage value's zeroness remains unchanged or
/// is set to zero.
pub const sreset: u64 = 2900;
/// Refund given (added into refund counter) when the storage value is set to zero from
/// non-zero.
pub const sclear: u64 = 4800;
/// Amount of gas to pay for a `SELFDESTRUCT` operation.
pub const selfdestruct: u64 = 5000;
/// Paid for a `CREATE` operation.
pub const create: u64 = 32000;
/// Paid per byte for a `CREATE` operation to succeed in placing code into state.
pub const codedeposit: u64 = 200;
/// Paid for a non-zero value transfer as part of the `CALL` operation.
pub const callvalue: u64 = 9000;
/// A stipend for the called contract subtracted from `callvalue` for a non-zero value transfer.
pub const callstipend: u64 = 2300;
/// Paid for a `CALL` or `SELFDESTRUCT` operation which creates an account.
pub const newaccount: u64 = 25000;
/// Partial payment for an `EXP` operation.
pub const exp: u64 = 10;
/// Partial payment when multiplied by the number of bytes in the exponent for the `EXP` operation.
pub const expbyte: u64 = 50;
/// Paid for every additional word when expanding memory.
pub const memory: u64 = 3;
/// Paid by all contract-creating transactions after the `Homestead` transition.
pub const txcreate: u64 = 32000;
/// Paid for every zero byte of data or code for a transaction.
pub const txdatazero: u64 = 4;
/// Paid for every non-zero byte of data or code for a transaction.
pub const txdatanonzero: u64 = 16;
/// Paid for every transaction.
pub const transaction: u64 = 21000;
/// Partial payment for a `LOG` operation.
pub const log: u64 = 375;
/// Paid for each byte in a `LOG` operation's data.
pub const logdata: u64 = 8;
/// Paid for each topic of a `LOG` operation.
pub const logtopic: u64 = 375;
/// Paid for each `KECCAK256` operation.
pub const keccak256: u64 = 30;
/// Paid for each word (rounded up) for input data to a `KECCAK256` operation.
pub const keccak256word: u64 = 6;
/// Partial payment for `*COPY` operations, multiplied by words copied, rounded up.
pub const copy: u64 = 3;
/// Payment for each `BLOCKHASH` operation.
pub const blockhash: u64 = 20;

/// Represents the state of gas during execution.
pub const Gas = struct {
    /// The initial gas limit.
    limit: u64,
    /// The total used gas.
    all_used_gas: u64,
    /// Used gas without memory expansion.
    used: u64,
    /// Used gas for memory expansion.
    memory: u64,
    /// Refunded gas. This is used only at the end of execution.
    refunded: i64,

    /// Creates a new `Gas` struct with the given gas limit.
    pub inline fn init(limit: u64) Gas {
        return .{
            .limit = limit,
            .all_used_gas = 0,
            .used = 0,
            .memory = 0,
            .refunded = 0,
        };
    }

    /// Returns all the gas used in the execution.
    pub fn spent(self: *Gas) u64 {
        return self.all_used_gas;
    }

    /// Returns the amount of gas remaining.
    pub fn remaining(self: *Gas) u64 {
        return self.limit - self.used;
    }

    /// Records an explicit cost.
    ///
    /// Returns `false` if the gas limit is exceeded.
    pub fn recordCost(self: *Gas, cost: u64) bool {
        const all_used_gas = self.all_used_gas +| cost;
        if (self.limit < all_used_gas) {
            return false;
        }

        self.used += cost;
        self.all_used_gas = all_used_gas;
        return true;
    }

    /// Records gas for memory expansion for the given number of 32-byte words.
    pub fn recordMemory(self: *Gas, num_words: u64) bool {
        const gas_memory = memoryGas(num_words);
        if (gas_memory > self.memory) {
            const all_used_gas = self.used +| gas_memory;
            if (self.limit < all_used_gas) {
                return false;
            }
            self.memory = gas_memory;
            self.all_used_gas = all_used_gas;
        }
        return true;
    }

    /// Records a refund value.
    ///
    /// `refund` can be negative but `self.refunded` should always be positive
    /// at the end of transact.
    pub fn recordRefund(self: *Gas, refund: i64) void {
        self.refunded += refund;
    }

    /// Erases a gas cost from the totals.
    pub fn eraseCost(self: *Gas, returned: u64) void {
        self.used -= returned;
        self.all_used_gas -= returned;
    }

    /// Sets a refund value for the final refund.
    ///
    /// The nax refund value is limited to the `n`th part (depending of fork) of gas spent.
    ///
    /// See also [EIP-3529: Reduction in refunds](https://eips.ethereum.org/EIPS/eip-3529).
    pub fn setFinalRefund(self: *Gas, rev: Rev) void {
        const max_refund_quotient = if (rev.enabled(.london)) 5 else 2;
        self.refunded = @min(self.refunded, @as(i64, @intCast(self.spent() / max_refund_quotient)));
    }
};

inline fn memoryGas(num_words: usize) u64 {
    const x = @as(u64, @intCast(num_words));
    return (memory *| x) +| ((x *| x) / 512);
}

pub inline fn expCost(power: u256, rev: Rev) ?u64 {
    if (power == 0) return exp;
    // EIP-160: EXP cost increase
    const gas_byte: u64 = if (rev.enabled(.spurious_dragon)) 50 else 10;
    const l = @as(u256, @intCast(exp));
    const r = checkedMul(gas_byte, log2floor(power) / 8 + 1) orelse return null;
    const gas = checkedAdd(l, @intCast(r)) orelse return null;
    return std.math.cast(u64, gas);
}

fn log2floor(value: u256) u64 {
    std.debug.assert(value != 0);
    return std.math.log2_int(u256, value);
}

pub inline fn copyCost(len: u64) ?u64 {
    return checkedAdd(verylow, costPerWord(len, copy) orelse return null);
}

pub inline fn keccak256Cost(len: u64) ?u64 {
    return checkedAdd(keccak256, costPerWord(len, keccak256word) orelse return null);
}

inline fn costPerWord(len: u64, multiple: u64) ?u64 {
    const b = std.math.divCeil(u64, len, 32) catch unreachable;
    return checkedMul(multiple, b);
}

inline fn checkedAdd(a: anytype, b: @TypeOf(a)) ?@TypeOf(a) {
    const x, const overflow = @addWithOverflow(a, b);
    return if (overflow != 0) null else x;
}

inline fn checkedMul(a: anytype, b: @TypeOf(a)) ?@TypeOf(a) {
    const x, const overflow = @mulWithOverflow(a, b);
    return if (overflow != 0) null else x;
}

test memoryGas {
    _ = memoryGas(std.math.maxInt(u32));
    _ = memoryGas(std.math.maxInt(u64) / 32);
    _ = memoryGas(std.math.maxInt(u64));
}
