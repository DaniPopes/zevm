//! Ethereum Virtual Machine (EVM) implementation.

const evmc = @import("evmc");
const std = @import("std");
const primitives = @import("../primitives.zig");

const Address = primitives.Address;
const B256 = primitives.B256;
const Rev = @import("../rev.zig").Rev;
const Allocator = std.mem.Allocator;
pub const Host = @import("Host.zig");
pub const Result = @import("Result.zig");
pub const Interpreter = @import("../interpreter/Interpreter.zig");

const Vm = @This();

frames: std.ArrayListUnmanaged(ExecFrame),
allocator: Allocator,

pub fn init(allocator: Allocator) !Vm {
    return .{
        .frames = try std.ArrayListUnmanaged(ExecFrame).initCapacity(allocator, 1025),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Vm) void {
    self.frames.deinit(self.allocator);
    self.* = undefined;
}

pub fn execute(self: *Vm, host: Host, rev: Rev, msg: *const evmc.evmc_message, code: []const u8) Result {
    const depth = @as(usize, @intCast(msg.depth));
    std.debug.assert(depth <= 1024);
    if (self.frames.items.len <= depth) {
        const prev_len = self.frames.items.len;
        self.frames.items.len = depth + 1;
        for (self.frames.items[prev_len..]) |*frame| {
            frame.interpreter = Interpreter.init(self.allocator) catch return .{ .status_code = .out_of_memory };
        }
    }
    var frame = &self.frames.items[depth];
    frame.interpreter.reset(msg, rev, host, code);
    const ir = frame.interpreter.run();
    const status_code = Result.StatusCode.fromInterpreter(ir);
    return .{
        .status_code = status_code,
        .gas_left = if (status_code == .success or status_code == .revert) @intCast(frame.interpreter.gas.remaining) else 0,
        .gas_refund = if (status_code == .success) frame.interpreter.gas.refunded else 0,
        .output = frame.interpreter.returnValue(),
    };
}

/// A single execution frame.
pub const ExecFrame = struct {
    interpreter: Interpreter,
};

/// The effect of an attempt to modify a contract storage item.
///
/// See the `evmc` storage status documentation for additional
/// information about design of this enum and analysis of the specification.
///
/// For the purpose of explaining the meaning of each element, the following
/// notation is used:
/// - 0 is zero value,
/// - X != 0 (X is any value other than 0),
/// - Y != 0, Y != X,  (Y is any value other than X and 0),
/// - Z != 0, Z != X, Z != X (Z is any value other than Y and X and 0),
/// - the "o -> c -> v" triple describes the change status in the context of:
///   - o: original value (cold value before a transaction started),
///   - c: current storage value,
///   - v: new storage value to be set.
///
/// The order of elements follows EIPs introducing net storage gas costs:
/// - EIP-2200: https://eips.ethereum.org/EIPS/eip-2200,
/// - EIP-1283: https://eips.ethereum.org/EIPS/eip-1283.
pub const StorageStatus = enum(evmc.enum_evmc_storage_status) {
    /// The new/same value is assigned to the storage item without affecting the cost structure.
    ///
    /// The storage value item is either:
    /// - left unchanged (c == v) or
    /// - the dirty value (o != c) is modified again (c != v).
    /// This is the group of cases related to minimal gas cost of only accessing warm storage.
    /// 0|X   -> 0 -> 0 (current value unchanged)
    /// 0|X|Y -> Y -> Y (current value unchanged)
    /// 0|X   -> Y -> Z (modified previously added/modified value)
    ///
    /// This is "catch all remaining" status. I.e. if all other statuses are correctly matched
    /// this status should be assigned to all remaining cases.
    assigned = evmc.EVMC_STORAGE_ASSIGNED,

    /// A new storage item is added by changing
    /// the current clean zero to a nonzero value.
    /// 0 -> 0 -> Z
    added = evmc.EVMC_STORAGE_ADDED,

    /// A storage item is deleted by changing
    /// the current clean nonzero to the zero value.
    /// X -> X -> 0
    deleted = evmc.EVMC_STORAGE_DELETED,

    /// A storage item is modified by changing
    /// the current clean nonzero to other nonzero value.
    /// X -> X -> Z
    modified = evmc.EVMC_STORAGE_MODIFIED,

    /// A storage item is added by changing
    /// the current dirty zero to a nonzero value other than the original value.
    /// X -> 0 -> Z
    deleted_added = evmc.EVMC_STORAGE_DELETED_ADDED,

    /// A storage item is deleted by changing
    /// the current dirty nonzero to the zero value and the original value is not zero.
    /// X -> Y -> 0
    modified_deleted = evmc.EVMC_STORAGE_MODIFIED_DELETED,

    /// A storage item is added by changing
    /// the current dirty zero to the original value.
    /// X -> 0 -> X
    deleted_restored = evmc.EVMC_STORAGE_DELETED_RESTORED,

    /// A storage item is deleted by changing
    /// the current dirty nonzero to the original zero value.
    /// 0 -> Y -> 0
    added_deleted = evmc.EVMC_STORAGE_ADDED_DELETED,

    /// A storage item is modified by changing
    /// the current dirty nonzero to the original nonzero value other than the current value.
    /// X -> Y -> X
    modified_restored = evmc.EVMC_STORAGE_MODIFIED_RESTORED,
};

/// Access status per EIP-2929: Gas cost increases for state access opcodes.
pub const AccessStatus = enum(evmc.enum_evmc_access_status) {
    /// The entry hasn't been accessed before – it's the first access.
    cold = evmc.EVMC_ACCESS_COLD,
    /// The entry is already in accessed_addresses or accessed_storage_keys.
    warm = evmc.EVMC_ACCESS_WARM,
};

/// The allocator used within EVMC contexts.
pub const evmc_allocator = std.heap.page_allocator;

export fn evmc_create_zevm() callconv(.c) [*c]evmc.evmc_vm {
    comptime std.debug.assert(@offsetOf(EvmcVm, "base") == 0);
    return @ptrCast(EvmcVm.create(evmc_allocator) catch null);
}

/// EVMC VM implementation.
pub const EvmcVm = struct {
    base: evmc.evmc_vm,
    vm: Vm,

    pub fn init(allocator: Allocator) !EvmcVm {
        return .{
            .base = .{
                .abi_version = evmc.EVMC_ABI_VERSION,
                .name = "zevm",
                .version = "0.1.0",
                .destroy = destroy,
                .execute = EvmcVm.execute,
                .get_capabilities = get_capabilities,
                .set_option = set_option,
            },
            .vm = try Vm.init(allocator),
        };
    }

    pub fn create(allocator: Allocator) !*EvmcVm {
        const vm = try allocator.create(EvmcVm);
        errdefer allocator.destroy(vm);
        vm.* = try EvmcVm.init(allocator);
        return vm;
    }

    pub fn deinit(self: *EvmcVm) void {
        self.vm.deinit();
    }

    fn destroy(vm_: [*c]evmc.evmc_vm) callconv(.c) void {
        const vm = @as(*EvmcVm, @ptrCast(vm_));
        vm.deinit();
        vm.vm.allocator.destroy(vm);
    }

    fn execute(vm_: [*c]evmc.evmc_vm, host_: [*c]const evmc.evmc_host_interface, context: ?*evmc.evmc_host_context, rev_: evmc.evmc_revision, msg: [*c]const evmc.evmc_message, code_: [*c]const u8, code_size: usize) callconv(.c) evmc.evmc_result {
        const vm = @as(*EvmcVm, @ptrCast(vm_));
        const host = Host.init(context, host_);
        const rev = @as(Rev, @enumFromInt(rev_));
        const code = code_[0..code_size];
        const result = vm.vm.execute(host, rev, msg, code);
        return result.intoEvmc();
    }

    fn get_capabilities(vm: [*c]evmc.evmc_vm) callconv(.c) evmc.evmc_capabilities_flagset {
        _ = vm;
        return evmc.EVMC_CAPABILITY_EVM1;
    }

    fn set_option(vm: [*c]evmc.evmc_vm, name: [*c]const u8, value: [*c]const u8) callconv(.c) evmc.evmc_set_option_result {
        _ = vm;
        _ = name;
        _ = value;
        return evmc.EVMC_SET_OPTION_INVALID_NAME;
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
