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

#### License

<sup>
Licensed under either of <a href="LICENSE-APACHE">Apache License, Version
2.0</a> or <a href="LICENSE-MIT">MIT license</a> at your option.
</sup>

<br>

<sub>
Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in these crates by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
</sub>
