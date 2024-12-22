//! EVM result.

const evmc = @import("evmc");
const std = @import("std");

const InstructionResult = @import("../interpreter/result.zig").InstructionResult;
const evmc_allocator = @import("Vm.zig").evmc_allocator;

status_code: StatusCode = .success,
gas_left: i64 = 0,
gas_refund: i64 = 0,
/// The return data. Empty or points into the VM's memory, which will be invalidated after the next call.
output: []const u8 = &[_]u8{},

/// Converts this result into an `evmc_result`.
pub fn intoEvmc(self: @This()) evmc.evmc_result {
    var result = evmc.evmc_result{
        .status_code = @intFromEnum(self.status_code),
        .gas_left = self.gas_left,
        .gas_refund = self.gas_refund,
    };
    if (self.output.len > 0) {
        const data = evmc_allocator.alloc(u8, self.output.len) catch {
            result.status_code = @intFromEnum(StatusCode.out_of_memory);
            return result;
        };
        result.output_data = data.ptr;
        result.output_size = data.len;
        result.release = release;
    }
    return result;
}

fn release(res: ?*const evmc.evmc_result) callconv(.C) void {
    if (res) |r| {
        evmc_allocator.free(r.output_data[0..r.output_size]);
    }
}

/// The execution status code.
///
/// Successful execution is represented by `success` having value 0.
///
/// Positive values represent failures defined by VM specifications with generic
/// `failure` code of value 1.
///
/// Status codes with negative values represent VM internal errors
/// not provided by EVM specifications. These errors MUST not be passed back
/// to the caller. They MAY be handled by the Client in predefined manner
/// (see e.g. `rejected`), otherwise internal errors are not recoverable.
/// The generic representant of errors is `internal_error` but
/// an EVM implementation MAY return negative status codes that are not defined
/// in the EVMC documentation.
///
/// In case new status codes are needed, please create an issue or pull request
/// in the EVMC repository (https://github.com/ethereum/evmc).
pub const StatusCode = enum(evmc.enum_evmc_status_code) {
    /// Execution finished with success.
    success = evmc.EVMC_SUCCESS,

    /// Generic execution failure.
    failure = evmc.EVMC_FAILURE,

    /// Execution terminated with REVERT opcode.
    ///
    /// In this case the amount of gas left MAY be non-zero and additional output
    /// data MAY be provided in ::evmc_result.
    revert = evmc.EVMC_REVERT,

    /// The execution has run out of gas.
    out_of_gas = evmc.EVMC_OUT_OF_GAS,

    /// The designated INVALID instruction has been hit during execution.
    ///
    /// The EIP-141 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-141.md)
    /// defines the instruction 0xfe as INVALID instruction to indicate execution
    /// abortion coming from high-level languages. This status code is reported
    /// in case this INVALID instruction has been encountered.
    invalid_instruction = evmc.EVMC_INVALID_INSTRUCTION,

    /// An undefined instruction has been encountered.
    undefined_instruction = evmc.EVMC_UNDEFINED_INSTRUCTION,

    /// The execution has attempted to put more items on the EVM stack
    /// than the specified limit.
    stack_overflow = evmc.EVMC_STACK_OVERFLOW,

    /// Execution of an opcode has required more items on the EVM stack.
    stack_underflow = evmc.EVMC_STACK_UNDERFLOW,

    /// Execution has violated the jump destination restrictions.
    bad_jump_destination = evmc.EVMC_BAD_JUMP_DESTINATION,

    /// Tried to read outside memory bounds.
    ///
    /// An example is RETURNDATACOPY reading past the available buffer.
    invalid_memory_access = evmc.EVMC_INVALID_MEMORY_ACCESS,

    /// Call depth has exceeded the limit (if any).
    call_depth_exceeded = evmc.EVMC_CALL_DEPTH_EXCEEDED,

    /// Tried to execute an operation which is restricted in static mode.
    static_mode_violation = evmc.EVMC_STATIC_MODE_VIOLATION,

    /// A call to a precompiled or system contract has ended with a failure.
    ///
    /// An example: elliptic curve functions handed invalid EC points.
    precompile_failure = evmc.EVMC_PRECOMPILE_FAILURE,

    /// Contract validation has failed (e.g. due to EVM 1.5 jump validity,
    /// Casper's purity checker or ewasm contract rules).
    contract_validation_failure = evmc.EVMC_CONTRACT_VALIDATION_FAILURE,

    /// An argument to a state accessing method has a value outside of the
    /// accepted range of values.
    argument_out_of_range = evmc.EVMC_ARGUMENT_OUT_OF_RANGE,

    /// A WebAssembly `unreachable` instruction has been hit during execution.
    wasm_unreachable_instruction = evmc.EVMC_WASM_UNREACHABLE_INSTRUCTION,

    /// A WebAssembly trap has been hit during execution. This can be for many
    /// reasons, including division by zero, validation errors, etc.
    wasm_trap = evmc.EVMC_WASM_TRAP,

    /// The caller does not have enough funds for value transfer.
    insufficient_balance = evmc.EVMC_INSUFFICIENT_BALANCE,

    /// EVM implementation generic internal error.
    internal_error = evmc.EVMC_INTERNAL_ERROR,

    /// The execution of the given code and/or message has been rejected
    /// by the EVM implementation.
    ///
    /// This error SHOULD be used to signal that the EVM is not able to or
    /// willing to execute the given code type or message.
    /// If an EVM returns the ::rejected status code,
    /// the Client MAY try to execute it in other EVM implementation.
    /// For example, the Client tries running a code in the EVM 1.5. If the
    /// code is not supported there, the execution falls back to the EVM 1.0.
    rejected = evmc.EVMC_REJECTED,

    /// The VM failed to allocate the amount of memory needed for execution.
    out_of_memory = evmc.EVMC_OUT_OF_MEMORY,

    pub fn fromInterpreter(ir: InstructionResult) StatusCode {
        const IR = InstructionResult;
        const SC = StatusCode;
        return switch (ir) {
            IR.Stop => SC.success,
            IR.Return => SC.success,
            IR.SelfDestruct => SC.success,
            IR.Revert => SC.revert,
            IR.CallTooDeep => SC.call_depth_exceeded,
            IR.OutOfFund => SC.insufficient_balance,
            IR.OutOfGas => SC.out_of_gas,
            IR.MemoryOOG => SC.out_of_gas,
            IR.MemoryLimitOOG => SC.out_of_gas,
            IR.PrecompileOOG => SC.out_of_gas,
            IR.InvalidOperandOOG => SC.argument_out_of_range,
            IR.OpcodeNotFound => SC.undefined_instruction,
            IR.CallNotAllowedInsideStatic => SC.static_mode_violation,
            IR.StateChangeDuringStaticCall => SC.static_mode_violation,
            IR.InvalidFEOpcode => SC.invalid_instruction,
            IR.InvalidJump => SC.bad_jump_destination,
            IR.NotActivated => SC.undefined_instruction,
            IR.StackUnderflow => SC.stack_underflow,
            IR.StackOverflow => SC.stack_overflow,
            IR.OutOfOffset => SC.argument_out_of_range,
            IR.CreateCollision => SC.failure,
            IR.OverflowPayment => SC.undefined_instruction,
            IR.PrecompileError => SC.precompile_failure,
            IR.NonceOverflow => SC.failure,
            IR.CreateContractSizeLimit => SC.contract_validation_failure,
            IR.CreateContractStartingWithEF => SC.contract_validation_failure,
            IR.CreateInitcodeSizeLimit => SC.contract_validation_failure,
            IR.FatalExternalError => SC.internal_error,
        };
    }
};
