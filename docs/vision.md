# Leanix Vision

Leanix is an experiment in **Nix flakes as Lean-checked build graphs**.

## Relationship to NixParserLean

`nixparserlean` is a faithful-modeling project. It parses Nix, validates Nix,
desugars Nix, and gradually gives existing Nix code a Lean semantics.

Leanix is the adjacent experiment: keep the reproducible-build idea, but move
the authoring language into Lean. Instead of accepting dynamically shaped
attribute sets and discovering mistakes late, Leanix should make build graph
shape, output names, system support, and source pinning explicit types.

Short version: what if flakes were typed first?

## What "Typed Flakes" Could Mean

A Nix flake is powerful because it packages inputs and outputs behind a stable
interface. It is weakly typed because most of that interface is an attrset
convention:

- `packages.${system}.default`
- `apps.${system}.foo`
- `devShells.${system}.default`
- `checks.${system}.bar`

Leanix can model those conventions directly:

- a `Package system` cannot accidentally become an app
- an `App system` must point at a package for the same system
- source pins can require hashes
- supported systems can be enumerated
- checks can be required to cover declared packages
- output schemas can be custom Lean structures instead of loose attrsets

The goal is not just "Nix syntax with types". The stronger idea is a typed build
graph that can be lowered to Nix when needed.

## Design Pressure

Leanix should stay honest about Nix's hard parts:

- builds are effectful even when derivations are pure descriptions
- the store path model matters
- fixed-output derivations and source fetching have special trust boundaries
- cross compilation needs explicit host/build/target distinctions
- flakes are partly package interface, partly lockfile protocol
- real reproducibility includes binary caches, substituters, signatures, and
  provenance, not just source hashes

That means the first model should be modest. It should encode the shape of typed
flake outputs before trying to reproduce the whole Nix evaluator.

## Possible End State

Leanix could become:

1. A Lean DSL for typed reproducible build graphs.
2. A verifier for flake-like interface contracts.
3. A renderer that emits ordinary `flake.nix`/derivation descriptions.
4. A proof playground for dependency closure, system compatibility, source
   pinning, and output-schema invariants.
