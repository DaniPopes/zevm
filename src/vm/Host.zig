//! EVM Host interface.
//!
//! Safe wrapper around `evmc_host_context` + `evmc_host_interface`.

const evmc = @import("evmc");
const std = @import("std");
const primitives = @import("../primitives.zig");

const Address = primitives.Address;
const B256 = primitives.B256;
const Vm = @import("Vm.zig");

const Host = @This();
const DummyHost = @import("DummyHost.zig");

context: ?*evmc.evmc_host_context,
vtable: *const evmc.evmc_host_interface,

pub fn dummy(allocator: std.mem.Allocator) !DummyHost {
    return DummyHost.init(allocator);
}

pub fn init(context: ?*evmc.evmc_host_context, vtable: *const evmc.evmc_host_interface) Host {
    return .{ .context = context, .vtable = vtable };
}

pub fn accountExists(self: Host, address: *const Address) bool {
    return (self.vtable.account_exists.?)(self.context, @ptrCast(address));
}
pub fn getStorage(self: Host, address: *const Address, key: *const B256) B256 {
    return B256.fromEvmc((self.vtable.get_storage.?)(self.context, @ptrCast(address), @ptrCast(key)));
}
pub fn setStorage(self: Host, address: *const Address, key: *const B256, value: *const B256) Vm.StorageStatus {
    return @enumFromInt((self.vtable.set_storage.?)(self.context, @ptrCast(address), @ptrCast(key), @ptrCast(value)));
}
pub fn getBalance(self: Host, address: *const Address) B256 {
    return B256.fromEvmc((self.vtable.get_balance.?)(self.context, @ptrCast(address)));
}
pub fn getCodeSize(self: Host, address: *const Address) usize {
    return (self.vtable.get_code_size.?)(self.context, @ptrCast(address));
}
pub fn getCodeHash(self: Host, address: *const Address) B256 {
    return B256.fromEvmc((self.vtable.get_code_hash.?)(self.context, @ptrCast(address)));
}
pub fn copyCode(self: Host, address: *const Address, offset: usize, to: []u8) usize {
    return (self.vtable.copy_code.?)(self.context, @ptrCast(address), offset, to.ptr, to.len);
}
pub fn selfdestruct(self: Host, address: *const Address, beneficiary: *const Address) bool {
    return (self.vtable.selfdestruct.?)(self.context, @ptrCast(address), @ptrCast(beneficiary));
}
pub fn call(self: Host, msg: *const evmc.evmc_message) evmc.evmc_result {
    return (self.vtable.call.?)(self.context, msg);
}
pub fn getTxContext(self: Host) evmc.evmc_tx_context {
    return (self.vtable.get_tx_context.?)(self.context);
}
pub fn getBlockHash(self: Host, number: i64) B256 {
    return B256.fromEvmc((self.vtable.get_block_hash.?)(self.context, number));
}
pub fn emitLog(self: Host, address: *const Address, data: []const u8, topics: []const B256) void {
    return (self.vtable.emit_log.?)(self.context, @ptrCast(address), data.ptr, data.len, @ptrCast(topics.ptr), topics.len);
}
pub fn accessAccount(self: Host, address: *const Address) Vm.AccessStatus {
    return @enumFromInt((self.vtable.access_account.?)(self.context, @ptrCast(address)));
}
pub fn accessStorage(self: Host, address: *const Address, key: *const B256) Vm.AccessStatus {
    return @enumFromInt((self.vtable.access_storage.?)(self.context, @ptrCast(address), @ptrCast(key)));
}
pub fn getTransientStorage(self: Host, address: *const Address, key: *const B256) B256 {
    return B256.fromEvmc((self.vtable.get_transient_storage.?)(self.context, @ptrCast(address), @ptrCast(key)));
}
pub fn setTransientStorage(self: Host, address: *const Address, key: *const B256, value: *const B256) void {
    return (self.vtable.set_transient_storage.?)(self.context, @ptrCast(address), @ptrCast(key), @ptrCast(value));
}
