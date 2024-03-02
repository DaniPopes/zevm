const std = @import("std");

const Interpreter = @import("../Interpreter.zig");
const Instruction = Interpreter.Instruction;
const InstructionResult = Interpreter.InstructionResult;
const utils = @import("utils.zig");

pub fn pop(int: *Interpreter) !void {
    _ = try int.stack.pop();
}

pub fn push(comptime n: comptime_int) Instruction {
    if (n > 32) {
        @compileError("invalid push instruction");
    }

    // no closures...
    const pushT = struct {
        fn push(int: *Interpreter) !void {
            if (n == 0) {
                return int.stack.push(0);
            }
            if (!int.inBounds(int.ip + n)) {
                return InstructionResult.OutOfOffset;
            }
            if (n == 1) {
                return int.stack.push(int.nextByte());
            }

            // @memcpy has way better codegen, `++` copies byte by byte for some reason
            // var bytes: [32]u8 = [_]u8{0} ** (32 - n) ++ int.nextByteSlice(n);
            comptime var bytes: [32]u8 = [_]u8{0} ** 32;
            @memcpy(bytes[32 - n ..], int.nextByteSlice(n));
            return int.stack.pushBeBytes(bytes);
        }
    };
    return pushT.push;
}

pub fn dup(comptime n: comptime_int) Instruction {
    if (n == 0 or n > 16) {
        @compileError("invalid dup instruction");
    }

    const dupT = struct {
        fn dup(int: *Interpreter) !void {
            return int.stack.dup(n);
        }
    };
    return dupT.dup;
}

pub fn swap(comptime n: comptime_int) Instruction {
    if (n == 0 or n > 16) {
        @compileError("invalid swap instruction");
    }

    const swapT = struct {
        fn swap(int: *Interpreter) !void {
            return int.stack.swap(n);
        }
    };
    return swapT.swap;
}

// pub fn dupn(int: *Interpreter) !void {
//     const x = try int.stack.pop();
//     const imm = try utils.castInt(u8, x);
//     const n = @as(u16, @intCast(imm)) + 1;
//     return int.stack.dup(n);
// }

// pub fn swapn(int: *Interpreter) !void {
//     const x = try int.stack.pop();
//     const imm = try utils.castInt(u8, x);
//     const n = @as(u16, @intCast(imm)) + 1;
//     return int.stack.swap(n);
// }
