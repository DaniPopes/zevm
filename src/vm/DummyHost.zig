const evmc = @import("evmc");
const std = @import("std");
const Vm = @import("Vm.zig");

const Self = @This();

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !Self {
    return .{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn host(self: *Self) Vm.Host {
    return .{ .context = @ptrCast(self), .vtable = &vtable };
}

const vtable = evmc.evmc_host_interface{
    .account_exists = account_exists,
    .get_storage = get_storage,
    .set_storage = set_storage,
    .get_balance = get_balance,
    .get_code_size = get_code_size,
    .get_code_hash = get_code_hash,
    .copy_code = copy_code,
    .selfdestruct = selfdestruct,
    .call = call,
    .get_tx_context = get_tx_context,
    .get_block_hash = get_block_hash,
    .emit_log = emit_log,
    .access_account = access_account,
    .access_storage = access_storage,
    .get_transient_storage = get_transient_storage,
    .set_transient_storage = set_transient_storage,
};

fn account_exists(cx_: ?*evmc.evmc_host_context, _: [*c]const evmc.evmc_address) callconv(.c) bool {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    return std.mem.zeroes(bool);
}
fn get_storage(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, key: [*c]const evmc.evmc_bytes32) callconv(.c) evmc.evmc_bytes32 {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = key;
    return std.mem.zeroes(evmc.evmc_bytes32);
}
fn set_storage(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, key: [*c]const evmc.evmc_bytes32, value: [*c]const evmc.evmc_bytes32) callconv(.c) evmc.evmc_storage_status {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = key;
    _ = value;
    return std.mem.zeroes(evmc.evmc_storage_status);
}
fn get_balance(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address) callconv(.c) evmc.evmc_bytes32 {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    return std.mem.zeroes(evmc.evmc_bytes32);
}
fn get_code_size(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address) callconv(.c) usize {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    return std.mem.zeroes(usize);
}
fn get_code_hash(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address) callconv(.c) evmc.evmc_bytes32 {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    return std.mem.zeroes(evmc.evmc_bytes32);
}
fn copy_code(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, offset: usize, buffer_data: [*c]u8, buffer_size: usize) callconv(.c) usize {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = offset;
    _ = buffer_data;
    _ = buffer_size;
    return std.mem.zeroes(usize);
}
fn selfdestruct(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, beneficiary: [*c]const evmc.evmc_address) callconv(.c) bool {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = beneficiary;
    return std.mem.zeroes(bool);
}
fn call(cx_: ?*evmc.evmc_host_context, msg: [*c]const evmc.evmc_message) callconv(.c) evmc.evmc_result {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = msg;
    return std.mem.zeroes(evmc.evmc_result);
}
fn get_tx_context(cx_: ?*evmc.evmc_host_context) callconv(.c) evmc.evmc_tx_context {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    return std.mem.zeroes(evmc.evmc_tx_context);
}
fn get_block_hash(cx_: ?*evmc.evmc_host_context, number: i64) callconv(.c) evmc.evmc_bytes32 {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = number;
    return std.mem.zeroes(evmc.evmc_bytes32);
}
fn emit_log(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, data: [*c]const u8, data_size: usize, topics: [*c]const evmc.evmc_bytes32, topics_count: usize) callconv(.c) void {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = data;
    _ = data_size;
    _ = topics;
    _ = topics_count;
}
fn access_account(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address) callconv(.c) evmc.evmc_access_status {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    return std.mem.zeroes(evmc.evmc_access_status);
}
fn access_storage(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, key: [*c]const evmc.evmc_bytes32) callconv(.c) evmc.evmc_access_status {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = key;
    return std.mem.zeroes(evmc.evmc_access_status);
}
fn get_transient_storage(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, key: [*c]const evmc.evmc_bytes32) callconv(.c) evmc.evmc_bytes32 {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = key;
    return std.mem.zeroes(evmc.evmc_bytes32);
}
fn set_transient_storage(cx_: ?*evmc.evmc_host_context, address: [*c]const evmc.evmc_address, key: [*c]const evmc.evmc_bytes32, value: [*c]const evmc.evmc_bytes32) callconv(.c) void {
    const cx = @as(*Self, @ptrCast(@alignCast(cx_)));
    _ = cx;
    _ = address;
    _ = key;
    _ = value;
}
