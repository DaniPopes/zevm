# zevm

[Ethereum Virtual Machine](https://ethereum.org/en/developers/docs/evm/) implementation in [Zig](https://ziglang.org).

Inspired by [REVM](https://github.com/bluealloy/revm).

## Usage

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
zig build -OReleaseFast -fstrip -femit-asm -femit-llvm-ir src/main.zig
```
