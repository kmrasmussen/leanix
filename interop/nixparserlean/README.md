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

Experimental local-checkout smoke test.

This is not a shared AST package, not a stable Lean dependency between the
repositories, and not a proof that nixparserlean can execute the generated
flake against real `nixpkgs`. Today the useful boundary is:

```text
Leanix value -> generated flake.nix -> nixparserlean --desugar / --eval
```

The `--eval` check evaluates the top-level flake record. It can produce an
`outputs` lambda closure, but it does not apply that closure to real flake
inputs.

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

The script renders selected Leanix examples into
`generated/interop-nixparserlean/`, then runs nixparserlean against each
generated flake with both `--desugar` and `--eval`.

It intentionally does not run `nix flake check`; Leanix's main Rust e2e
harness already owns the Nix backend smoke test.

## Non-Goals

- No cross-repo Lean import yet.
- No shared package or version lock yet.
- No machine-readable AST contract yet; nixparserlean still prints `repr`.
- No full Nix evaluation claim.

If this bridge becomes load-bearing, the next step is to move the same check
into the Rust e2e harness with a configurable nixparserlean path.
