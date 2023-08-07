const std = @import("std");
const expect = std.testing.expect;

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
        return comptime Stack{
            .data = undefined,
            .len = 0,
        };
    }

    /// Returns the slice of the stack's initialized data.
    pub fn dataSlice(self: *Stack) []const u256 {
        return self.data[0..self.len];
    }

    /// Pushes a new element onto the stack, or returns `null` if the stack is full.
    pub fn push(self: *Stack, value: u256) ?void {
        self.pushn(1, .{value});
    }

    /// Pushes multiple elements onto the stack, or returns `null` if the stack is full.
    pub fn pushn(self: *Stack, comptime n: usize, values: [n]u256) ?void {
        if (self.len + n == stack_size) {
            return null;
        }
        inline for (values) |val| {
            self.data[self.len] = val;
            self.len += 1;
        }
    }

    /// Removes the topmost element from the stack and returns it, or `null` if it is empty.
    pub fn pop(self: *Stack) ?u256 {
        var values = self.popn(1) orelse return null;
        return values[0];
    }

    /// Removes the topmost `n` elements from the stack and returns them, or `null` if it is empty.
    pub fn popn(self: *Stack, comptime n: usize) ?[n]u256 {
        if (self.len == 0 or self.len < n) {
            return null;
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

    /// Returns a pointer to the topmost element of the stack, or `null` if it is empty.
    pub fn top(self: *Stack) ?*u256 {
        if (self.len == 0) {
            return null;
        }
        return &self.data[self.len - 1];
    }

    /// Removes the topmost element from the stack and returns it, along with the new topmost
    /// element.
    pub fn popTop(self: *Stack) ?PopTop {
        var value = self.pop() orelse return null;
        var top_ = self.top() orelse return null;
        return PopTop{ .value = value, .top = top_ };
    }

    /// Removes the topmost `n` elements from the stack and returns them, along with the new topmost
    /// element.
    pub fn popnTop(self: *Stack, comptime n: usize) ?PopNTop(n) {
        if (self.len == 0 or self.len < n) {
            return null;
        }
        return .{
            .values = self.popn(n) orelse .{},
            .top = self.top().?,
        };
    }
};

test "stack push and pop" {
    var stack = Stack.new();
    stack.pushn(3, .{ 0, 1, 2 }).?;
    try expect(stack.len == 3);

    try expect(std.mem.eql(u256, &stack.popn(1).?, &[_]u256{2}));
    try expect(stack.len == 2);

    try expect(std.mem.eql(u256, &stack.popn(2).?, &[_]u256{ 1, 0 }));
    try expect(stack.len == 0);

    @setEvalBranchQuota(Stack.stack_size);
    stack.pushn(Stack.stack_size - 1, .{0} ** (Stack.stack_size - 1)).?;
    var data_before = stack.dataSlice();
    try expect(stack.pushn(1, .{0}) == null);
    var data_after = stack.dataSlice();
    try expect(std.mem.eql(u256, data_after, data_before));
}

test "stack top" {
    var stack = Stack.new();
    stack.pushn(3, .{ 0, 1, 2 }).?;

    var top = stack.top().?;
    try expect(top.* == 2);
    top.* = 42;
    try expect(stack.data[2] == 42);

    var pop_top = stack.popTop().?;
    try expect(pop_top.value == 42);
    try expect(pop_top.top.* == 1);
    pop_top.top.* = 43;
    try expect(stack.data[1] == 43);
}

test "stack pop top" {
    var stack = Stack.new();
    stack.pushn(3, .{ 0, 1, 2 }).?;

    var popn_top = stack.popnTop(0).?;
    try expect(popn_top.values.len == 0);
    try expect(popn_top.top == stack.top().?);
}
