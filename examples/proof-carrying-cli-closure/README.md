# Proof-Carrying CLI Closure

This is the current Leanix showcase.

It demonstrates:

- a `CliProject` schema
- validation into `ValidatedSchema`
- proof fields for the CLI schema contract
- an extra package dependency in the schema output
- package closure validation before rendering
- a structured `runSteps` builder for an executable wrapper
- rendering to an ordinary `flake.nix`
- checking the generated flake with Nix through the Rust e2e harness

## Run

From the repository root:

```sh
nix develop -c lake exe leanix render-showcase --out generated/flake.nix
nix flake check path:./generated
```

Or run the full e2e harness:

```sh
nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

## Source

The typed source is `showcaseCliProject` in:

```text
Leanix/Examples.lean
```

The generated flake is an artifact. The source of truth is the Lean value.
