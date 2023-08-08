const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;

const utils = @import("utils.zig");

pub const Memory = struct {
    /// The pointer to the allocated memory.
    ptr: [*]u8,
    /// The length of the initialized memory.
    len: usize,
    /// The size of allocated memory.
    capacity: usize,
    allocator: Allocator,

    /// The size of allocation "page".
    pub const page_size = 4 * 1024;

    /// Creates a new Memory object with the initial capacity allocation.
    pub fn init(allocator: Allocator) Allocator.Error!Memory {
        var x = try allocator.alloc(u8, page_size);
        assert(x.len == page_size);
        // @memset(x, 0);
        return .{
            .ptr = x.ptr,
            .len = 0,
            .capacity = page_size,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Memory) void {
        self.allocator.free(self.ptr[0..self.capacity]);
    }

    /// Returns all of the initialized data.
    pub fn data(self: *Memory) []u8 {
        return self.ptr[0..self.len];
    }

    /// Returns the entire memory. May be partly uninitialized.
    pub fn rawData(self: *Memory) []u8 {
        return self.ptr[0..self.capacity];
    }

    /// Returns a slice of the initalized data.
    pub fn getSlice(self: *Memory, offset: usize, size: usize) []u8 {
        return self.data()[offset..][0..size];
    }

    /// Returns a slice of the initalized data.
    pub fn getArray(self: *Memory, offset: usize, comptime size: usize) *[size]u8 {
        return self.data()[offset..][0..size];
    }

    /// Returns a slice of the entire memory.
    pub fn getRawSlice(self: *Memory, offset: usize, size: usize) []u8 {
        return self.rawData()[offset..][0..size];
    }

    /// Resizes the memory to `new_len`. Allocates if `new_len > self.capacity`.
    /// `new_len` must be a multiple of 32.
    pub fn resize(self: *Memory, new_len: usize) Allocator.Error!void {
        if (new_len > self.capacity) try self.grow(new_len);
        self.len = new_len;
    }

    /// Truncates the memory to `new_len`. This is a no-op if `new_len >= self.len`.
    pub fn truncate(self: *Memory, new_len: usize) void {
        if (new_len >= self.len) return;
        self.len = new_len;
    }

    /// Clears the memory by settings its length to zero.
    pub fn clear(self: *Memory) void {
        self.len = 0;
    }

    pub fn setByte(self: *Memory, offset: usize, byte: u8) void {
        self.data()[offset] = byte;
    }

    pub fn setU256(self: *Memory, offset: usize, value: *u256) void {
        self.set(offset, @as(*[32]u8, @ptrCast(value))[0..]);
    }

    pub fn set(self: *Memory, offset: usize, value: []u8) void {
        @memcpy(self.getSlice(offset, value.len), value.ptr);
    }

    pub fn copy(self: *Memory, dst: usize, src: usize, len: usize) void {
        @memcpy(self.getSlice(dst, len), self.getSlice(src, len));
    }

    pub fn dump(self: *Memory) void {
        if (self.len == 0) return;
        std.log.debug("Memory:", .{});
        utils.dumpSlice(self.data());
    }

    fn grow(self: *Memory, new_len: usize) Allocator.Error!void {
        assert(new_len % 32 == 0);
        assert(new_len > self.len);

        var new_capacity = self.capacity;
        if (new_len > new_capacity) {
            new_capacity *= 2;

            if (new_len > new_capacity) {
                new_capacity = ((new_len + (page_size - 1)) / page_size) * page_size;
            }
        }

        var new_data = try self.allocator.realloc(self.rawData(), new_capacity);
        // @memset(new_data, 0);
        self.ptr = new_data.ptr;
        self.capacity = new_data.len;
    }
};

test "memory resize" {
    var memory = try Memory.init(std.testing.allocator);
    defer memory.deinit();
    try expect(memory.data().len == 0);
    try expect(memory.capacity == Memory.page_size);

    try memory.resize(32);
    try expect(memory.data().len == 32);
    try expect(memory.capacity == Memory.page_size);

    try memory.resize(Memory.page_size);
    try expect(memory.data().len == Memory.page_size);
    try expect(memory.capacity == Memory.page_size);

    try memory.resize(Memory.page_size + 32);
    try expect(memory.data().len == Memory.page_size + 32);
    try expect(memory.capacity == Memory.page_size * 2);
}
