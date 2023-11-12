# zevm

[Ethereum Virtual Machine](https://ethereum.org/en/developers/docs/evm/) implementation in [Zig](https://ziglang.org).

Inspired by [REVM](https://github.com/bluealloy/revm).

## Usage

Tested with Zig 0.11.0.

- Run:
```sh
zig build run
```

- Test:
```sh
zig build test
```

- Emit LLVM-IR and ASM:
```sh
zig build-exe -OReleaseFast -fstrip -femit-asm -femit-llvm-ir -lc src/main.zig
```
