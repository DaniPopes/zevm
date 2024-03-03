//! A simple dynamically resizable memory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const utils = @import("utils.zig");

const Self = @This();
const Inner = std.ArrayList(u8);

inner: Inner,

/// The size of allocation "page".
pub const page_size = 4 * 1024;

/// Creates a new Self object with the initial capacity allocation.
pub fn init(allocator: Allocator) Allocator.Error!Self {
    return .{ .inner = try Inner.initCapacity(allocator, page_size) };
}

pub fn deinit(self: *Self) void {
    self.inner.deinit();
}

/// Returns all of the initialized data.
pub fn data(self: *Self) []u8 {
    return self.inner.items;
}

/// Returns the length of the initialized data.
pub fn len(self: *Self) usize {
    return self.inner.items.len;
}

/// Returns the entire memory. May be partly uninitialized.
pub fn rawData(self: *Self) []u8 {
    return self.inner.allocatedSlice();
}

/// Returns the length of the entire memory.
pub fn capacity(self: *Self) usize {
    return self.inner.capacity;
}

/// Returns a slice of the initalized data.
pub fn getSlice(self: *Self, offset: usize, size: usize) []u8 {
    return self.data()[offset..][0..size];
}

/// Returns a slice of the initalized data.
pub fn getArray(self: *Self, offset: usize, comptime size: usize) *[size]u8 {
    return self.data()[offset..][0..size];
}

/// Returns a slice of the entire memory.
pub fn getRawSlice(self: *Self, offset: usize, size: usize) []u8 {
    return self.rawData()[offset..][0..size];
}

/// Resizes the memory to `new_len`. Allocates if `new_len > self.capacity`.
/// `new_len` must be a multiple of 32.
pub fn resize(self: *Self, new_len: usize) Allocator.Error!void {
    try self.inner.ensureTotalCapacity(new_len);
    @memset(self.inner.unusedCapacitySlice(), 0);
    self.inner.items.len = new_len;
}

/// Truncates the memory to `new_len`. This is a no-op if `new_len >= self.len`.
pub fn truncate(self: *Self, new_len: usize) void {
    if (new_len >= self.inner.items.len) return;
    self.inner.items.len = new_len;
}

/// Clears the memory by settings its length to zero.
pub fn clear(self: *Self) void {
    self.inner.clearRetainingCapacity();
}

pub fn setByte(self: *Self, offset: usize, byte: u8) void {
    self.data()[offset] = byte;
}

pub fn setU256(self: *Self, offset: usize, value: u256) void {
    const value_be = std.mem.nativeToBig(u256, value);
    const value_bytes = std.mem.asBytes(&value_be);
    self.set(offset, value_bytes);
}

pub fn set(self: *Self, offset: usize, value: []const u8) void {
    @memcpy(self.getSlice(offset, value.len), value.ptr);
}

pub fn copy(self: *Self, dst: usize, src: usize, size: usize) void {
    @memcpy(self.getSlice(dst, size), self.getSlice(src, size));
}

pub fn dump(self: *Self) void {
    if (self.inner.items.len == 0) return;
    std.log.debug("Stack:", .{});
    utils.dumpSlice(self.data());
}

test resize {
    var memory = try Self.init(std.testing.allocator);
    defer memory.deinit();

    try expectEqual(memory.data().len, 0);
    try expectEqual(memory.capacity(), Self.page_size);

    try memory.resize(32);
    try expectEqual(memory.data().len, 32);
    try expectEqual(memory.capacity(), Self.page_size);

    try memory.resize(Self.page_size);
    try expectEqual(memory.data().len, Self.page_size);
    try expectEqual(memory.capacity(), Self.page_size);

    try memory.resize(Self.page_size + 32);
    try expectEqual(memory.data().len, Self.page_size + 32);
    try expectEqual(memory.capacity(), Self.page_size + (Self.page_size / 2) + 8);
}

test set {
    var memory = try Self.init(std.testing.allocator);
    defer memory.deinit();

    try memory.resize(64);
    try expectEqualSlices(u8, memory.data(), &[_]u8{0} ** 64);

    memory.setByte(0, 1);
    try expectEqual(memory.data()[0], 1);

    memory.setByte(31, 42);
    try expectEqual(memory.data()[31], 42);

    memory.setU256(0, 69);
    try expectEqualSlices(u8, memory.data()[0..31], &[_]u8{0} ** 31);
    try expectEqual(memory.data()[31], 69);
}
