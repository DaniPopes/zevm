//! Ethereum primitives.

const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub const Address = FixedBytes(20);
pub const B256 = FixedBytes(32);

/// Fixed-size byte array.
///
/// This is a transparent wrapper around `[size]u8` to provide utility constructors and methods.
pub fn FixedBytes(comptime size: usize) type {
    return struct {
        bytes: [size]u8,

        const Self = @This();

        pub fn fromEvmc(value: anytype) Self {
            return Self{ .bytes = value.bytes };
        }

        pub fn fromArray(bytes: [size]u8) Self {
            return Self{ .bytes = bytes };
        }

        pub fn fromRef(bytes: *const [size]u8) *const Self {
            return @ptrCast(bytes);
        }
        pub fn fromMut(bytes: *[size]u8) *Self {
            return @ptrCast(bytes);
        }

        pub fn fromBytes(bytes: []const u8) ?*const Self {
            if (bytes.len < size) {
                return null;
            }
            return @as(*const Self, @ptrCast(bytes.ptr));
        }
        pub fn fromBytesMut(bytes: []u8) ?*Self {
            return @constCast(Self.fromBytes(bytes));
        }

        pub fn asBytes(self: *const Self) []const u8 {
            return &self.bytes;
        }

        pub fn fromHex(hex: []const u8) !Self {
            var bytes: [size]u8 = undefined;
            _ = try std.fmt.hexToBytes(&bytes, hex);
            return .{ .bytes = bytes };
        }

        pub fn toHex(self: *const Self, case: std.fmt.Case) [size * 2]u8 {
            return std.fmt.bytesToHex(&self.bytes, case);
        }
    };
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

test "FixedBytes.fromBytes" {
    const z = FixedBytes(3).fromBytes(&[_]u8{});
    try expectEqual(z, null);
    const a = FixedBytes(3).fromBytes(&[_]u8{1});
    try expectEqual(a, null);
    const b = FixedBytes(3).fromBytes(&[_]u8{ 1, 2 });
    try expectEqual(b, null);
    const c = FixedBytes(3).fromBytes(&[_]u8{ 1, 2, 3 });
    try expectEqual(c.?.*, FixedBytes(3){ .bytes = [3]u8{ 1, 2, 3 } });
    const d = FixedBytes(3).fromBytes(&[_]u8{ 1, 2, 3, 4 });
    try expectEqual(d.?.*, c.?.*);
}

test "FixedBytes.asBytes" {
    const c = FixedBytes(3).fromBytes(&[_]u8{ 1, 2, 3 });
    try expectEqual(c.?.asBytes(), &[_]u8{ 1, 2, 3 });
}

test "FixedBytes hex" {
    const c = try FixedBytes(5).fromHex("010203abcd");
    try std.testing.expectEqualSlices(u8, c.asBytes(), &[_]u8{ 1, 2, 3, 0xab, 0xcd });
    try std.testing.expectEqualStrings(&c.toHex(.lower), "010203abcd");
    try std.testing.expectEqualStrings(&c.toHex(.upper), "010203ABCD");
}
