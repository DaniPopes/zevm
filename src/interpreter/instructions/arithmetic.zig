const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const gas = Interpreter.gas;
const InstructionResult = Interpreter.InstructionResult;

pub fn add(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = value +% top.*;
}

pub fn mul(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value, const top = try int.stack.popTop();
    top.* = value *% top.*;
}

pub fn sub(int: *Interpreter) !void {
    try int.recordGas(gas.verylow);
    const value, const top = try int.stack.popTop();
    top.* = value -% top.*;
}

pub fn div(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value, const top = try int.stack.popTop();
    if (top.* != 0) {
        top.* = value / top.*;
    }
}

pub fn sdiv(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value, const top = try int.stack.popTop();
    if (top.* == 0) {
        return;
    }
    const first = @as(i256, @bitCast(value));
    const second = @as(i256, @bitCast(top.*));
    if (first == std.math.minInt(i256) and second == -1) {
        top.* = std.math.maxInt(u256);
        return;
    }
    top.* = @bitCast(@divFloor(first, second));
}

pub fn mod(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value, const top = try int.stack.popTop();
    if (top.* != 0) {
        top.* = value % top.*;
    }
}

pub fn smod(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value, const top = try int.stack.popTop();
    if (top.* != 0) {
        const first = @as(i256, @bitCast(value));
        const second = @as(i256, @bitCast(top.*));
        top.* = @bitCast(@mod(first, second));
    }
}

pub fn addmod(int: *Interpreter) !void {
    try int.recordGas(gas.mid);
    const x = try int.stack.popnTop(2);
    x.top.* = u256_addmod(x.values[0], x.values[1], x.top.*);
}

pub fn mulmod(int: *Interpreter) !void {
    try int.recordGas(gas.mid);
    // TODO
}

pub fn exp(int: *Interpreter) !void {
    var value, const top = try int.stack.popTop();
    // note we're not using `std.math.powi` because we want wrapping behaviour
    var exponent = top.*;
    try int.recordGasOpt(gas.expCost(exponent, int.revision()));
    var result: u256 = 1;
    while (exponent > 1) {
        if (exponent & 1 == 1) {
            result *%= value;
        }
        exponent >>= 1;
        value *%= value;
    }
    top.* = result;
}

pub fn signextend(int: *Interpreter) !void {
    try int.recordGas(gas.low);
    const value_, const top = try int.stack.popTop();
    if (value_ < 32) {
        const value: u8 = @intCast(value_);
        const bit_index = 8 * value + 7;
        const bit = ((top.* >> bit_index) & 1) != 0;
        const mask = (@as(u256, 1) << bit_index) - 1;
        top.* = if (bit) top.* | ~mask else top.* & mask;
    }
}

fn u256_addmod(lhs: u256, rhs: u256, modulus: u256) u256 {
    // Reduce inputs.
    const lhs_ = u256_reduceMod(lhs, modulus);
    const rhs_ = u256_reduceMod(rhs, modulus);

    // Compute the sum and conditionally subtract modulus once.
    var sum, const overflow = @addWithOverflow(lhs_, rhs_);
    if (overflow != 0 or sum >= modulus) {
        sum -= modulus;
    }
    return sum;
}

fn u256_reduceMod(x: u256, modulus: u256) u256 {
    if (modulus == 0) {
        return 0;
    }
    if (x >= modulus) {
        return x % modulus;
    }
    return x;
}
