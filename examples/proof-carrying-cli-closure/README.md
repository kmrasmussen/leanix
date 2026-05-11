# Proof-Carrying CLI Closure

This is the current Leanix showcase.

It demonstrates:

- a `CliProject` schema
- validation into `ValidatedSchema`
- proof fields for the CLI schema contract
- an extra package dependency in the schema output
- package closure validation before rendering
- a structured `runSteps` builder that installs an executable wrapper script
- a `CheckedPackageGraph` proof witness for package reference closure and the
  finite acyclicity check
- rendering to an ordinary `flake.nix`
- checking the generated flake with Nix through the Rust e2e harness

## Run

From the repository root:

```sh
nix develop -c lake exe leanix render-showcase --out generated/flake.nix
nix flake check path:./generated
```

To check the standalone Lean excerpt:

```sh
nix develop -c lake env lean examples/proof-carrying-cli-closure/source.lean
```

Or run the full e2e harness:

```sh
nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

To emit the proof-carrying artifact directly:

```sh
nix develop -c lake exe leanix emit-artifact --out generated/showcase-artifact
nix develop -c lake exe leanix verify-artifact generated/showcase-artifact
nix flake check path:./generated/showcase-artifact
```

## Source

The local excerpt is:

```text
examples/proof-carrying-cli-closure/source.lean
```

It imports `Leanix.Examples` and re-exports the canonical definitions used by
the renderer. The canonical project source is `showcaseCliProject` in:

```text
Leanix/Examples.lean
```

That keeps the excerpt executable without duplicating package and schema values.

The expected rendered Nix is:

```text
examples/proof-carrying-cli-closure/expected.flake.nix
```

The expected proof-carrying artifact files are:

```text
examples/proof-carrying-cli-closure/artifact/
```

They can be checked directly with:

```sh
nix develop -c lake exe leanix verify-artifact examples/proof-carrying-cli-closure/artifact
```

The generated flake is an artifact. The source of truth is the Lean value.
