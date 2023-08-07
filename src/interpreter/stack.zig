const std = @import("std");
const expect = std.testing.expect;

const InstructionResult = @import("interpreter.zig").InstructionResult;

/// A simple stack implementation that uses a fixed-size array for storage.
pub const Stack = struct {
    /// The stack's data.
    data: [stack_size]u256,
    /// The number of elements that have been pushed onto the stack.
    len: usize,

    /// The maximum number of elements that can be stored in the stack.
    const stack_size = 1024;

    /// The return type of `popTop`.
    const PopTop = struct { value: u256, top: *u256 };

    /// The return type of `popnTop`.
    pub fn PopNTop(comptime n: usize) type {
        return struct { values: [n]u256, top: *u256 };
    }

    /// Create a new uninitialized stack with length 0.
    pub fn new() Stack {
        return comptime .{
            .data = undefined,
            .len = 0,
        };
    }

    /// Returns the slice of the stack's initialized data.
    pub fn dataSlice(self: *Stack) []const u256 {
        return self.data[0..self.len];
    }

    /// Pushes a new element onto the stack, or returns `StackOverflow` if the stack is full.
    pub fn push(self: *Stack, value: u256) !void {
        try self.pushn(1, .{value});
    }

    /// Pushes a new big-endian byte array onto the stack, or returns `StackOverflow` if the stack
    /// is full.
    pub fn pushBeBytes(self: *Stack, bytes: [32]u8) !void {
        // BE -> LE
        var value: u256 = @bitCast(bytes);
        if (@import("builtin").cpu.arch.endian() == .Little) {
            value = @byteSwap(value);
        }
        try self.pushn(1, .{value});
    }

    /// Pushes `n` elements onto the stack, or returns `StackOverflow` if the stack is full.
    pub fn pushn(self: *Stack, comptime n: usize, values: [n]u256) !void {
        if (self.len + n == stack_size) {
            return InstructionResult.StackOverflow;
        }
        inline for (values) |val| {
            self.data[self.len] = val;
            self.len += 1;
        }
    }

    /// Removes the topmost element from the stack and returns it, or `StackUnderflow` if it is
    /// empty.
    pub fn pop(self: *Stack) !u256 {
        return (try self.popn(1))[0];
    }

    /// Removes the topmost `n` elements from the stack and returns them, or `StackUnderflow` if it
    /// is empty.
    pub fn popn(self: *Stack, comptime n: usize) ![n]u256 {
        if (self.len == 0 or self.len < n) {
            return InstructionResult.StackUnderflow;
        }
        self.len -%= n;

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
    pub fn top(self: *Stack) !*u256 {
        if (self.len == 0) {
            return InstructionResult.StackUnderflow;
        }
        return &self.data[self.len - 1];
    }

    /// Removes the topmost element from the stack and returns it, along with the new topmost
    /// element.
    pub fn popTop(self: *Stack) !PopTop {
        var x = try self.popnTop(1);
        return .{ .value = x.values[0], .top = x.top };
    }

    /// Removes the topmost `n` elements from the stack and returns them, along with the new topmost
    /// element.
    pub fn popnTop(self: *Stack, comptime n: usize) !PopNTop(n) {
        if (self.len == 0 or self.len < n + 1) {
            return InstructionResult.StackUnderflow;
        }
        return .{
            .values = self.popn(n) catch unreachable,
            .top = self.top() catch unreachable,
        };
    }

    /// Duplicates the `N`th value from the top of the stack.
    pub fn dup(self: *Stack, comptime n: usize) !void {
        var len = self.len;
        if (len < n) {
            return InstructionResult.StackUnderflow;
        }
        return self.push(self.data[len - n]);
    }

    /// Swaps the topmost value with the `N`th value from the top.
    pub fn swap(self: *Stack, comptime n: usize) !void {
        var len = self.len;
        if (len <= n) {
            return InstructionResult.StackUnderflow;
        }
        var last = len - 1;
        std.mem.swap(u256, &self.data[last], &self.data[last - n]);
    }

    pub fn dump(self: *Stack) void {
        var i = self.len;
        if (i > 0) {
            std.log.debug("Stack dump:", .{});
        }
        while (true) {
            if (i == 0) {
                break;
            }
            i -= 1;
            var item = self.data[i];
            std.log.debug("{: >4}: 0x{x:0>64}", .{ i, item });
        }
    }
};

test "stack push and pop" {
    var stack = Stack.new();
    try stack.pushn(3, .{ 0, 1, 2 });
    try expect(stack.len == 3);

    try expect(std.mem.eql(u256, &try stack.popn(1), &[_]u256{2}));
    try expect(stack.len == 2);

    try expect(std.mem.eql(u256, &try stack.popn(2), &[_]u256{ 1, 0 }));
    try expect(stack.len == 0);

    @setEvalBranchQuota(Stack.stack_size);
    try stack.pushn(Stack.stack_size - 1, .{0} ** (Stack.stack_size - 1));
    var data_before = stack.dataSlice();
    try expect(stack.pushn(1, .{0}) == null);
    var data_after = stack.dataSlice();
    try expect(std.mem.eql(u256, data_after, data_before));
}

test "stack top" {
    var stack = Stack.new();
    try stack.pushn(3, .{ 0, 1, 2 });

    var top = try stack.top();
    try expect(stack.len == 3);
    try expect(top.* == 2);
    top.* = 42;
    try expect(stack.data[2] == 42);

    var pop_top = try stack.popTop();
    try expect(stack.len == 2);
    try expect(pop_top.value == 42);
    try expect(pop_top.top.* == 1);
    pop_top.top.* = 43;
    try expect(stack.data[1] == 43);

    var popn_top = try stack.popnTop(2);
    _ = popn_top;
    try expect(stack.len == 0);
}

test "stack pop top" {
    var stack = Stack.new();
    stack.pushn(3, .{ 0, 1, 2 }).?;

    var popn_top = stack.popnTop(0).?;
    try expect(popn_top.values.len == 0);
    try expect(popn_top.top == stack.top().?);
}
