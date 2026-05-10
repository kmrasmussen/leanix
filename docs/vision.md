# Leanix Vision

Leanix is an experiment in **Nix flakes as Lean-checked build graphs**.

## Relationship to NixParserLean

`nixparserlean` is a faithful-modeling project. It parses Nix, validates Nix,
desugars Nix, and gradually gives existing Nix code a Lean semantics.

Leanix is the adjacent experiment: keep the reproducible-build idea, but move
the authoring language into Lean. Instead of accepting dynamically shaped
attribute sets and discovering mistakes late, Leanix makes build graph shape,
output names, system support, and source pinning explicit types.

Short version: what if flakes were typed first?

## What "Typed Flakes" Means in Leanix Today

A Nix flake is powerful because it packages inputs and outputs behind a stable
interface. It is weakly typed because most of that interface is an attrset
convention:

- `packages.${system}.default`
- `apps.${system}.foo`
- `devShells.${system}.default`
- `checks.${system}.bar`

Leanix models those conventions directly. The current model in `Leanix/Core.lean`
gives:

- a finite enumeration `System` (`x86_64-linux`, `aarch64-linux`,
  `x86_64-darwin`, `aarch64-darwin`)
- `Package system`, `App system`, `DevShell system`, `Check system` indexed by
  `System` so an output cannot accidentally float to the wrong platform
- `BuildExpr` with constructors for `nixpkgs` lookups, flake-input paths, typed
  package references (`BuildExpr.package`), raw shell `runCommand`, and a small
  structured `runSteps` (copy source, install executable script, build Lean
  project, mkdir, writeFile, chmodExecutable, raw run). Generated script/file
  text can use `BuildText` fragments so package references inside content are
  validated instead of hiding as raw Nix interpolation.
- `Input` with a `flake` / fixed-output `source` / `localDevSource` /
  `impureLocalSource` distinction. Fetch-like `source` pins must carry a
  `narHash`; local sources are explicitly development-only or impure.
- a `Flake` record carrying a description, named inputs, and `Outputs` indexed
  by `System`

On top of that, `Leanix/Schema.lean` introduces typed output schemas:

- a `FlakeSchema` class (`toOutputs`, `validate`, `Valid : schema -> Prop`)
- the first concrete schema, `CliProject system`, with one project package,
  optional extra packages, a default app, default dev shell, and default check
- `CliProject.Valid` records the equalities and membership facts that
  `validateChecked` establishes
- a `ValidatedSchema schema` wrapper that carries `FlakeSchema.Valid value`
- a `ValidatedFlake` wrapper that carries evidence that `validateFlake`
  succeeded
- `Flake.fromValidatedSchema` and `Flake.fromSchema` for the two entry styles;
  both produce `ValidatedFlake` before rendering

## Design Pressure

Leanix should stay honest about Nix's hard parts:

- builds are effectful even when derivations are pure descriptions
- the store path model matters
- fixed-output derivations and source fetching have special trust boundaries
- cross compilation needs explicit host/build/target distinctions
- flakes are partly package interface, partly lockfile protocol
- real reproducibility includes binary caches, substituters, signatures, and
  provenance, not just source hashes

The current model is deliberately modest. It captures the shape of typed flake
outputs and a small graph invariant (package closure, no cycles) before trying
to reproduce the Nix evaluator.

## Possible End State

Leanix could become:

1. A Lean DSL for typed reproducible build graphs.
2. A verifier for flake-like interface contracts.
3. A renderer that emits ordinary `flake.nix`/derivation descriptions.
4. A proof playground for dependency closure, system compatibility, source
   pinning, and output-schema invariants.
5. A producer of proof-carrying flake artifacts that bundle source, manifest,
   checked invariants, and a verifiable Nix witness (see TICKET-0007).
