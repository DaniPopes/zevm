const std = @import("std");
const debug = std.log.debug;

const Stack = @import("stack.zig").Stack;
const Opcode = @import("opcode.zig").Opcode;
const InstructionResult = @import("result.zig").InstructionResult;

pub const Interpreter = struct {
    /// The bytecode slice.
    bytecode: []const u8,

    /// The current instruction pointer. This always points into `bytecode`.
    ip: [*]const u8,

    /// The execution control flag. If this is not set to `Continue`, the interpreter will stop
    /// execution.
    res: InstructionResult,

    /// The stack.
    stack: Stack,

    pub fn new(bytecode: []const u8) Interpreter {
        return Interpreter{
            .bytecode = bytecode,
            .ip = bytecode.ptr,
            .res = .Continue,
            .stack = Stack.new(),
        };
    }

    /// Returns the current program counter.
    pub fn pc(self: *Interpreter) usize {
        _ = self;
        return 0;
        // return self.ip - &self.bytecode[0];
    }

    pub fn run(self: *Interpreter) void {
        var c: usize = 0;
        while (self.res == .Continue) {
            c += 1;
            self.step();
        }
        debug("Executed {} instructions, result: {}", .{ c, self.res });
    }

    fn inBounds(self: *Interpreter) bool {
        var ip = @intFromPtr(self.ip);
        var start = @intFromPtr(self.bytecode.ptr);
        var ret = ip >= start and ip <= start + self.bytecode.len;
        if (ret) {
            self.res = InstructionResult.OutOfOffset;
        }
        return ret;
    }

    pub fn step(self: *Interpreter) void {
        var opcode = self.ip[0];
        if (std.log.defaultLogEnabled(.debug)) {
            var as_enum = @as(Opcode, @enumFromInt(opcode));
            debug("{: >4}: {} (0x{X:0>2})", .{ self.pc(), as_enum, opcode });
        }
        self.ip += 1;
        if (!self.inBounds()) {
            self.res = .OutOfOffset;
            return;
        }
        self.eval(opcode);
    }

    fn eval(self: *Interpreter, opcode: u8) void {
        switch (@as(Opcode, @enumFromInt(opcode))) {
            .STOP => self.stop(),

            .ADD => self.add(),
            .MUL => self.mul(),
            .SUB => self.sub(),
            .DIV => self.div(),
            .SDIV => self.sdiv(),
            .MOD => self.mod(),
            .SMOD => self.smod(),
            .ADDMOD => self.addmod(),
            .MULMOD => self.mulmod(),
            .EXP => self.exp(),
            .SIGNEXTEND => self.signextend(),

            else => self.unimplemented(""),
        }
    }

    fn stop(self: *Interpreter) void {
        self.res = .Stop;
    }

    fn add(self: *Interpreter) void {
        if (self.stack.popTop()) |x| {
            x.top.* = x.value + x.top.*;
        }
    }

    fn mul(self: *Interpreter) void {
        self.unimplemented("MUL");
    }

    fn sub(self: *Interpreter) void {
        self.unimplemented("SUB");
    }

    fn div(self: *Interpreter) void {
        self.unimplemented("DIV");
    }

    fn sdiv(self: *Interpreter) void {
        self.unimplemented("SDIV");
    }

    fn mod(self: *Interpreter) void {
        self.unimplemented("MOD");
    }

    fn smod(self: *Interpreter) void {
        self.unimplemented("SMOD");
    }

    fn addmod(self: *Interpreter) void {
        self.unimplemented("ADDMOD");
    }

    fn mulmod(self: *Interpreter) void {
        self.unimplemented("MULMOD");
    }

    fn exp(self: *Interpreter) void {
        self.unimplemented("EXP");
    }

    fn signextend(self: *Interpreter) void {
        self.unimplemented("SIGNEXTEND");
    }

    fn unimplemented(self: *Interpreter, comptime name: []const u8) void {
        std.log.warn("unimplemented opcode: {s}", .{name});
        self.res = .Revert;
    }
};
