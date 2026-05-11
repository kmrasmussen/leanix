# NixParserLean Interop

This directory holds the experimental bridge from Leanix to
`nixparserlean`.

Leanix owns the typed build graph and renders ordinary `flake.nix` files.
`nixparserlean` owns the Lean-side model of existing Nix syntax, desugaring,
validation, and a small evaluator. The bridge asks a narrow question:

```text
Does Leanix currently render Nix that stays inside nixparserlean's supported
dialect?
```

## Status

Experimental local-checkout smoke test, owned by the Rust e2e harness.

This is not a shared AST package, not a stable Lean dependency between the
repositories, and not a proof that nixparserlean can execute the generated
flake against real `nixpkgs`. Today the useful boundary is:

```text
Leanix value -> generated flake.nix -> nixparserlean --desugar JSON / --eval
```

For selected cases, the Rust harness consumes nixparserlean's
`--desugar --format json` output and checks a small parsed-output summary:
output families, systems, package/app/dev-shell/check names, and synthetic
default-package references. The `--eval` check still evaluates only the
top-level flake record. It can produce an `outputs` lambda closure, but it does
not apply that closure to real flake inputs.

## Layout

```text
interop/nixparserlean/
  README.md
  run.sh
```

## Requirements

- This repository is checked out as `leanix`.
- `nixparserlean` is checked out as a sibling directory:
  `../nixparserlean`.
- Both projects build through their own flake dev shells.

Set `NIXPARSERLEAN_DIR` to override the sibling checkout path:

```sh
NIXPARSERLEAN_DIR=/path/to/nixparserlean interop/nixparserlean/run.sh
```

## Usage

From the Leanix repo root:

```sh
interop/nixparserlean/run.sh
```

The script is a convenience wrapper around the Rust e2e harness:

```sh
cargo run --locked --manifest-path e2e/runner/Cargo.toml -- \
  --nixparserlean-dir ../nixparserlean \
  --only-nixparserlean-interop
```

The full e2e harness also accepts `--nixparserlean-dir PATH`. When provided, it
runs the normal Leanix e2e cases and then runs nixparserlean interop. Without
that flag, and without `NIXPARSERLEAN_DIR`, the normal e2e run prints an
explicit skip message for this optional bridge.

The interop suite renders selected Leanix examples into
`generated/interop-nixparserlean/`, then runs nixparserlean against each
generated flake with both `--desugar --format json` and `--eval`. Parsed-output
contracts currently cover the hello, CLI schema, showcase, and multi-system
examples.

It intentionally does not run `nix flake check`; Leanix's main Rust e2e
harness already owns the Nix backend smoke test.

## Non-Goals

- No cross-repo Lean import yet.
- No shared package or version lock yet.
- No full shared AST package yet; Leanix consumes nixparserlean's current JSON
  shape as a narrow interop contract.
- No full Nix evaluation claim.

The next step is to make the parsed summary richer and less string-fragment
based, ideally with an explicit summary mode in nixparserlean.
