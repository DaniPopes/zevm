const std = @import("std");

const interpreter = @import("root").interpreter;
const Instruction = interpreter.Instruction;
const InstructionResult = interpreter.InstructionResult;
const Interpreter = interpreter.Interpreter;

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
