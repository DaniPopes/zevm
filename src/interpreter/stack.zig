const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const debug = std.log.debug;

const InstructionResult = @import("interpreter.zig").InstructionResult;

/// A simple stack implementation that uses a fixed-size array for storage.
pub const Stack = struct {
    /// The stack's data.
    data: [capacity]u256,
    /// The number of elements that have been pushed onto the stack.
    len: usize,

    /// The maximum number of elements that can be stored in the stack.
    const capacity = 1024;

    /// The return type of `popTop`.
    const PopTop = struct { value: u256, top: *u256 };

    /// The return type of `popnTop`.
    pub fn PopNTop(comptime n: usize) type {
        return struct { values: [n]u256, top: *u256 };
    }

    /// Create a new uninitialized stack with length 0.
    pub fn init() Stack {
        return comptime .{
            .data = undefined,
            .len = 0,
        };
    }

    /// Returns the slice of the stack's initialized data.
    pub fn dataSlice(self: *Stack) []const u256 {
        return self.data[0..self.len];
    }

    /// Pushes a new big-endian byte array onto the stack, or returns `StackOverflow` if the stack
    /// is full.
    pub inline fn pushBeBytes(self: *Stack, bytes: [32]u8) !void {
        return self.push(std.mem.bigToNative(u256, @as(u256, @bitCast(bytes))));
    }

    /// Pushes a new element onto the stack, or returns `StackOverflow` if the stack is full.
    pub inline fn push(self: *Stack, value: u256) !void {
        return self.pushn(1, .{value});
    }

    /// Pushes `n` elements onto the stack, or returns `StackOverflow` if the stack is full.
    pub fn pushn(self: *Stack, comptime n: usize, values: [n]u256) !void {
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
    pub inline fn pop(self: *Stack) !u256 {
        return (try self.popn(1))[0];
    }

    /// Removes the topmost `n` elements from the stack and returns them, or `StackUnderflow` if it
    /// is empty.
    pub fn popn(self: *Stack, comptime n: usize) ![n]u256 {
        if (self.len == 0 or self.len < n) return InstructionResult.StackUnderflow;
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
    pub fn top(self: *Stack) !*u256 {
        if (self.len == 0) return InstructionResult.StackUnderflow;
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
        if (self.len == 0 or self.len < n + 1) return InstructionResult.StackUnderflow;
        return .{
            .values = self.popn(n) catch unreachable,
            .top = self.top() catch unreachable,
        };
    }

    /// Duplicates the `N`th value from the top of the stack.
    pub inline fn dup(self: *Stack, comptime n: usize) !void {
        var len = self.len;
        if (len < n) return InstructionResult.StackUnderflow;
        return self.push(self.data[len - n]);
    }

    /// Swaps the topmost value with the `N`th value from the top.
    pub inline fn swap(self: *Stack, comptime n: usize) !void {
        var len = self.len;
        if (len <= n) return InstructionResult.StackUnderflow;
        var last = len - 1;
        std.mem.swap(u256, &self.data[last], &self.data[last - n]);
    }

    pub fn dump(self: *Stack) void {
        if (self.len == 0) return;
        debug("Stack:", .{});
        var i = self.len;
        while (i > 0) {
            i -= 1;
            var item = self.data[i];
            debug("{: >4}: 0x{x:0>64}", .{ i, item });
        }
    }
};

test "stack push and pop" {
    var stack = Stack.init();
    try stack.pushn(3, .{ 0, 1, 2 });
    try expect(stack.len == 3);

    try expect(std.mem.eql(u256, &try stack.popn(1), &[_]u256{2}));
    try expect(stack.len == 2);

    try expect(std.mem.eql(u256, &try stack.popn(2), &[_]u256{ 1, 0 }));
    try expect(stack.len == 0);

    @setEvalBranchQuota(Stack.capacity);
    try stack.pushn(Stack.capacity, .{0} ** Stack.capacity);
    try expect(stack.len == Stack.capacity);

    try expectError(InstructionResult.StackOverflow, stack.pushn(1, .{0}));
    try expect(stack.len == Stack.capacity);
}

test "stack top" {
    var stack = Stack.init();
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

    try expectError(InstructionResult.StackUnderflow, stack.popnTop(2));
    _ = try stack.popnTop(1);
    try expect(stack.len == 1);
}

test "stack pop top" {
    var stack = Stack.init();
    try stack.pushn(3, .{ 0, 1, 2 });

    var popn_top = try stack.popnTop(0);
    try expect(popn_top.values.len == 0);
    try expect(popn_top.top == try stack.top());
}
