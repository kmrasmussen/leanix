# Multi-System Schema

Leanix now has a typed authoring schema for one CLI project emitted across
multiple systems.

The renderer already knew how to emit output blocks for more than one system.
That was graph-level support: if a checked `Outputs` value had packages for
`x86_64-linux` and `aarch64-linux`, the renderer could print both. The new
`MultiSystemCliProject` schema moves that capability up to the authoring layer.
It groups optional per-system `CliProject` values under one logical project
name, requires at least two active systems, validates each active project with
the existing CLI schema rules, and then lowers to ordinary `Outputs`.

The first example keeps the shape intentionally small: the same `hello` CLI
project is emitted for `x86_64-linux` and `aarch64-linux`. The Rust e2e harness
now golden-compares the generated flake and runs `nix flake check` on it. It
also covers an invalid multi-system schema where the aarch64 app points at a
missing package, which proves that per-system schema validation failures are
reported at the multi-system boundary.

This is still not host/build/target modeling or cross compilation. It is the
smaller milestone Leanix needed first: a logical typed project can describe
more than one active system before it becomes a generated `flake.nix`.
