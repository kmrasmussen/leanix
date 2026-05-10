# AGENTS

## Mission

Leanix is an experiment in **Nix flakes as Lean-checked build graphs**.

It keeps the Nix goal of reproducible builds, but moves the authoring model into
Lean: typed output schemas, explicit source pins, system-indexed packages,
validated build graphs, and eventually proofs about the graph before anything
builds.

This project is adjacent to `nixparserlean`. `nixparserlean` asks, "what does
existing Nix mean?" Leanix asks, "what if flakes were typed first?"

## Working Style

- Keep the model small and executable before adding proof obligations.
- Prefer explicit typed structures over stringly-typed attrset conventions.
- Separate pure build graph modeling from any future shelling out to Nix.
- Put harnesses, e2e tests, subprocess orchestration, filesystem crawling, and
  cache/lockfile workflows in Rust rather than Lean.
- Treat Nix interop as an output/backend problem, not as the source of truth.
- Run `lake build` after Lean changes.
- Run `cargo run --locked --manifest-path e2e/runner/Cargo.toml` after renderer,
  CLI, generated-flake, or e2e changes.
- Write design notes when introducing major concepts.
- Write dated blog notes in `blog/yyyy-mm-dd-hh-mm-name.md` for meaningful
  project steps.

## Near-Term Direction

The first proof of concept should be a typed hello flake:

- describe one package, one app, one dev shell, and one check as Lean values
- index those outputs by `System`
- validate simple invariants, such as "apps point at packages for the same
  system" and "source-like inputs have hashes"
- render the checked graph to a small ordinary `flake.nix`
- run the rendered flake with Nix as an interop smoke test

The milestone is not completeness. The milestone is seeing one tiny build graph
move through this path:

```text
Lean value -> validation -> generated flake.nix -> nix build/check
```

After that, grow the model only where the PoC exposes pressure.
