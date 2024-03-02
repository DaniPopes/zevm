//! A simple dynamically resizable memory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const utils = @import("utils.zig");

const Self = @This();

/// The pointer to the allocated memory.
ptr: [*]u8,
/// The length of the initialized memory.
len: usize,
/// The size of allocated memory.
capacity: usize,
allocator: Allocator,

/// The size of allocation "page".
pub const page_size = 4 * 1024;

/// Creates a new Self object with the initial capacity allocation.
pub fn init(allocator: Allocator) Allocator.Error!Self {
    const x = try allocator.alloc(u8, page_size);
    assert(x.len == page_size);
    @memset(x, 0);
    return .{
        .ptr = x.ptr,
        .len = 0,
        .capacity = page_size,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.ptr[0..self.capacity]);
}

/// Returns all of the initialized data.
pub fn data(self: *Self) []u8 {
    return self.ptr[0..self.len];
}

/// Returns the entire memory. May be partly uninitialized.
pub fn rawData(self: *Self) []u8 {
    return self.ptr[0..self.capacity];
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
    if (new_len > self.capacity) try self.grow(new_len);
    self.len = new_len;
}

/// Truncates the memory to `new_len`. This is a no-op if `new_len >= self.len`.
pub fn truncate(self: *Self, new_len: usize) void {
    if (new_len >= self.len) return;
    self.len = new_len;
}

/// Clears the memory by settings its length to zero.
pub fn clear(self: *Self) void {
    self.len = 0;
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

pub fn copy(self: *Self, dst: usize, src: usize, len: usize) void {
    @memcpy(self.getSlice(dst, len), self.getSlice(src, len));
}

pub fn dump(self: *Self) void {
    if (self.len == 0) return;
    std.log.debug("Stack:", .{});
    utils.dumpSlice(self.data());
}

fn grow(self: *Self, new_len: usize) Allocator.Error!void {
    assert(new_len % 32 == 0);
    assert(new_len > self.len);

    var new_capacity = self.capacity;
    if (new_len > new_capacity) {
        new_capacity *= 2;

        if (new_len > new_capacity) {
            new_capacity = ((new_len + (page_size - 1)) / page_size) * page_size;
        }
    }

    const new_data = try self.allocator.realloc(self.rawData(), new_capacity);
    @memset(new_data, 0);
    self.ptr = new_data.ptr;
    self.capacity = new_data.len;
}

test resize {
    var memory = try Self.init(std.testing.allocator);
    defer memory.deinit();

    try expectEqual(memory.data().len, 0);
    try expectEqual(memory.capacity, Self.page_size);

    try memory.resize(32);
    try expectEqual(memory.data().len, 32);
    try expectEqual(memory.capacity, Self.page_size);

    try memory.resize(Self.page_size);
    try expectEqual(memory.data().len, Self.page_size);
    try expectEqual(memory.capacity, Self.page_size);

    try memory.resize(Self.page_size + 32);
    try expectEqual(memory.data().len, Self.page_size + 32);
    try expectEqual(memory.capacity, Self.page_size * 2);
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
