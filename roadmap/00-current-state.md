# Current State

This is a snapshot of the project after the completed ticket wave ending at
commit `0eacfac` (`Add typed check commands`).

## Repository State

- The main branch is up to date with `origin/main`.
- All `.tickets/TICKET-0001` through `.tickets/TICKET-0025` are marked
  `completed`.
- Two untracked files exist locally, `flagged.md` and `result`. They are not
  part of the tracked project state and should not be treated as roadmap input
  unless intentionally reviewed later.
- The reliable verification path is still through the flake dev shell:
  `nix develop --command ...`.

## Implemented Model

The core model lives in `Leanix/Core.lean`.

Implemented:

- supported systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`,
  `aarch64-darwin`
- input kinds: flake inputs, fixed-output sources, local development sources,
  and explicitly impure local sources
- package, app, dev shell, and check outputs indexed by `System`
- structured build text with typed package, input, and output-path fragments
- `BuildExpr` as the current Nix backend representation
- `BuildStep` structured operations, including source copy, file copy,
  executable installation, Lean project build, `mkdir`, file writes, chmod, and
  raw command escape hatches
- `BuildPlan` as a first backend-neutral authoring layer over common package
  intentions
- typed builder identities for known nixpkgs packages, executable wrappers, and
  input-tree copies
- `CheckCommand` as a typed check-command surface with raw shell as an explicit
  escape hatch

## Implemented Validation

Validation lives mostly in `Leanix/Validate.lean` and `Leanix/Schema.lean`.

Implemented:

- duplicate input and output name checks
- source inputs require a `narHash`
- build expression input references resolve
- build expression package references resolve
- typed build text package references resolve
- build plan package/input references resolve before lowering
- duplicate wrapper arguments are rejected at the build-plan layer
- check command package/input references resolve
- package env vars reject unsupported builder forms
- duplicate env vars are rejected
- package dependency cycles are rejected by fuel-bounded reachability
- package closure evidence is carried through named properties:
  `PackageClosure.ReferencesResolve` and
  `PackageClosure.NoFuelBoundedCycles`

## Implemented Schemas

The schema layer is no longer just a single CLI shape.

Implemented:

- `CliProject`: package, default app, default dev shell, default check
- `MultiSystemCliProject`: one logical CLI project across multiple active
  systems
- `LibraryProject`: package-first library-style output with default dev shell
  and check conventions
- `MultiAppProject`: one package graph exposed through multiple apps
- `ValidatedSchema`: explicit boundary before schema lowering
- `Flake.fromSchema` and `Flake.fromValidatedSchema`: schema-to-validated-flake
  paths

Missing:

- formatter-oriented schemas
- service/daemon schemas
- documentation or website schemas
- data-only/package-set schemas
- schemas with policy knobs, such as "default app required" versus "all apps
  named"

## Rendering and Artifacts

Implemented:

- `ValidatedFlake` is the renderer boundary.
- Generated Nix emits active-system output blocks.
- Package and app defaults are synthesized where needed.
- String escaping and attr-name quoting are handled.
- Fixed-output sources render through `builtins.fetchTree`.
- Development sources remain non-flake source inputs with trust-boundary
  comments.
- `emit-artifact` writes `flake.nix` and `leanix.manifest.json`.
- `verify-artifact` checks the current artifact contract and replays the source
  elaboration plus `nix flake check`.
- Artifact manifests record input trust classes, pin policy, rev/hash metadata,
  systems, packages, app/check references, checked invariants, and replay
  commands.
- Artifact verification rejects floating flake inputs without pinned ref or
  lockfile witness evidence.

Important boundary:

- The artifact verifier currently verifies the showcase contract, not arbitrary
  manifests.
- The manifest is emitted by Lean code as JSON text, not parsed through a robust
  JSON library.

## Rust E2E Harness

The Rust e2e harness in `e2e/runner` is central infrastructure.

It currently covers:

- rendering valid examples
- comparing selected generated flakes to goldens
- running `nix flake check path:./generated`
- proof-carrying artifact emission and verification
- policy rejection for floating artifact inputs
- invalid examples with exact stderr checks
- optional nixparserlean interop through `--nixparserlean-dir`

The harness deliberately has no external Rust crates.

## NixParserLean Interop

The interop lane under `interop/nixparserlean/` is narrow and useful.

Current claim:

```text
Leanix value -> generated flake.nix -> nixparserlean --desugar JSON / --eval
```

It does not prove full semantic equivalence with Nix evaluation. It checks that
generated flakes stay inside a subset that `nixparserlean` can parse, desugar,
and evaluate at the top-level flake record.

Next pressure:

- replace string-fragment JSON checks with a richer parsed summary contract
- keep this as Rust-owned interop rather than a direct Lean dependency until the
  shared contract is more stable

## Near-Term Project Shape

Leanix is now past the initial PoC. The next version should be a narrow,
coherent system with:

- a small schema catalog
- typed build plans as the main package-authoring API
- fewer raw shell paths in normal examples
- stronger proof-carrying graph values
- artifact manifests that are verifiable beyond the showcase
- explicit interop contracts with generated Nix
