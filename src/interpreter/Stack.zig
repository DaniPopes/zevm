//! A simple stack implementation that uses a fixed-size array for storage.

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectError = std.testing.expectError;
const debug = std.log.debug;

const InstructionResult = @import("interpreter.zig").InstructionResult;

/// The stack's data.
data: [capacity]u256,
/// The number of elements that have been pushed onto the stack.
len: usize,

/// The maximum number of elements that can be stored in the stack.
const capacity = 1024;

const Self = @This();

/// The return type of `popnTop`.
pub fn PopNTop(comptime n: usize) type {
    return struct { values: [n]u256, top: *u256 };
}

/// Create a new uninitialized stack with length 0.
pub fn init() Self {
    return comptime .{
        .data = undefined,
        .len = 0,
    };
}

/// Returns the slice of the stack's initialized data.
pub fn dataSlice(self: *Self) []const u256 {
    return self.data[0..self.len];
}

/// Pushes a new big-endian byte array onto the stack, or returns `StackOverflow` if the stack
/// is full.
pub inline fn pushBeBytes(self: *Self, bytes: [32]u8) !void {
    return self.push(std.mem.bigToNative(u256, @as(u256, @bitCast(bytes))));
}

/// Pushes a new element onto the stack, or returns `StackOverflow` if the stack is full.
pub inline fn push(self: *Self, value: u256) !void {
    return self.pushn(1, .{value});
}

/// Pushes `n` elements onto the stack, or returns `StackOverflow` if the stack is full.
pub fn pushn(self: *Self, comptime n: usize, values: [n]u256) !void {
    if (self.len + n > capacity) {
        return InstructionResult.StackOverflow;
    }
    inline for (values) |val| {
        self.data[self.len] = val;
        self.len += 1;
    }
}

/// Removes the topmost element from the stack and returns it, or `StackUnderflow` if it is
/// empty.
pub inline fn pop(self: *Self) !u256 {
    return (try self.popn(1))[0];
}

/// Removes the topmost `n` elements from the stack and returns them, or `StackUnderflow` if it
/// is empty.
pub fn popn(self: *Self, comptime n: usize) ![n]u256 {
    if (self.len < n) return InstructionResult.StackUnderflow;
    self.len -= n;

    var ret: [n]u256 = undefined;
    comptime var i = n;
    inline for (&ret) |*r| {
        i -= 1;
        r.* = self.data[self.len + i];
    }
    return ret;
}

/// Returns a pointer to the topmost element of the stack, or `StackUnderflow` if it
/// is empty.
pub fn top(self: *Self) !*u256 {
    if (self.len == 0) return InstructionResult.StackUnderflow;
    return &self.data[self.len - 1];
}

/// Removes the topmost element from the stack and returns it, along with the new topmost
/// element.
pub fn popTop(self: *Self) !struct { u256, *u256 } {
    const x = try self.popnTop(1);
    return .{ x.values[0], x.top };
}

/// Removes the topmost `n` elements from the stack and returns them, along with the new topmost
/// element.
pub fn popnTop(self: *Self, comptime n: usize) !PopNTop(n) {
    if (self.len < n + 1) return InstructionResult.StackUnderflow;
    return .{
        .values = self.popn(n) catch unreachable,
        .top = self.top() catch unreachable,
    };
}

/// Duplicates the `n`th value from the top of the stack.
/// `n` cannot be `0`.
pub inline fn dup(self: *Self, n: usize) !void {
    const len = self.len;
    if (n == 0) unreachable;
    if (len < n) return InstructionResult.StackUnderflow;
    if (len + 1 > capacity) return InstructionResult.StackOverflow;
    return self.push(self.data[len - n]);
}

/// Swaps the topmost value with the `n`th value from the top.
pub inline fn swap(self: *Self, n: usize) !void {
    const len = self.len;
    if (len <= n) return InstructionResult.StackUnderflow;
    const last = len - 1;
    std.mem.swap(u256, &self.data[last], &self.data[last - n]);
}

pub fn dump(self: *Self) void {
    if (self.len == 0) return;
    debug("Self:", .{});
    var i = self.len;
    while (i > 0) {
        i -= 1;
        const item = self.data[i];
        debug("{: >4}: 0x{x:0>64}", .{ i, item });
    }
}

test "stack push and pop" {
    var stack = Self.init();
    try stack.pushn(3, .{ 0, 1, 2 });
    try expectEqual(stack.len, 3);

    try expectEqualSlices(u256, &try stack.popn(1), &[_]u256{2});
    try expectEqual(stack.len, 2);

    try expectEqualSlices(u256, &try stack.popn(2), &[_]u256{ 1, 0 });
    try expectEqual(stack.len, 0);

    @setEvalBranchQuota(Self.capacity);
    try stack.pushn(Self.capacity, .{0} ** Self.capacity);
    try expectEqual(stack.len, Self.capacity);

    try expectError(InstructionResult.StackOverflow, stack.pushn(1, .{0}));
    try expectEqual(stack.len, Self.capacity);
}

test top {
    var stack = Self.init();
    try stack.pushn(3, .{ 0, 1, 2 });

    const x = try stack.top();
    try expectEqual(stack.len, 3);
    try expectEqual(x.*, 2);
    x.* = 42;
    try expectEqual(stack.data[2], 42);

    const value, const top_ = try stack.popTop();
    try expectEqual(stack.len, 2);
    try expectEqual(value, 42);
    try expectEqual(top_.*, 1);
    top_.* = 43;
    try expectEqual(stack.data[1], 43);

    try expectError(InstructionResult.StackUnderflow, stack.popnTop(2));
    _ = try stack.popnTop(1);
    try expectEqual(stack.len, 1);
}

test popnTop {
    var stack = Self.init();
    try stack.pushn(3, .{ 0, 1, 2 });

    const popn_top = try stack.popnTop(0);
    try expectEqual(popn_top.values.len, 0);
    try expectEqual(popn_top.top, try stack.top());
}

test swap {
    var stack = Self.init();
    try stack.pushn(3, .{ 0, 1, 2 });

    try stack.swap(0);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2 });

    try stack.swap(1);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 2, 1 });

    try stack.swap(1);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2 });

    try stack.swap(2);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 2, 1, 0 });

    try stack.swap(1);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 2, 0, 1 });
}

test dup {
    var stack = Self.init();
    try stack.pushn(3, .{ 0, 1, 2 });

    try expectError(InstructionResult.StackUnderflow, stack.dup(4));

    try stack.dup(1);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2, 2 });

    try stack.dup(3);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2, 2, 1 });

    try stack.dup(5);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2, 2, 1, 0 });

    try stack.dup(2);
    try expectEqualSlices(u256, stack.dataSlice(), &[_]u256{ 0, 1, 2, 2, 1, 0, 1 });
}
