# Current State

This is a snapshot of the project after the completed ticket wave ending at
commit `4182005` (`Add next roadmap ticket wave`), plus the current
`ServiceProject` schema work.

## Repository State

- The main branch is up to date with `origin/main`.
- All `.tickets/TICKET-0001` through `.tickets/TICKET-0033` are marked
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
- package, app, dev shell, check, and formatter outputs indexed by `System`
- structured build text with typed package, input, and output-path fragments
- `BuildExpr` as the current Nix backend representation
- `BuildStep` structured operations, including source copy, text-file install,
  file copy, executable installation, Lean project build, `mkdir`, file writes,
  chmod, and raw command escape hatches
- `BuildPlan` as the first backend-neutral authoring layer over common package
  intentions
- typed builder identities for known nixpkgs packages, executable wrappers,
  input-tree/file copies, text-file installation, package executable runs, and
  Lean package builds from input trees
- `CheckCommand` as a typed check-command surface with raw shell as an explicit
  escape hatch
- `EscapePolicy` with development and strict artifact modes

## Implemented Validation

Validation lives mostly in `Leanix/Validate.lean` and `Leanix/Schema.lean`.

Implemented:

- duplicate input and output name checks
- source inputs require a `narHash`
- build expression input references resolve
- build expression package references resolve
- typed build text package/input references resolve
- build plan package/input references resolve before lowering
- build plan paths reject empty paths, parent traversal, absolute host paths,
  and output destinations outside `$out`
- duplicate wrapper arguments are rejected at the build-plan layer
- check command package/input references resolve
- formatter package references resolve
- package env vars reject unsupported builder forms
- duplicate env vars are rejected
- package dependency cycles are rejected by fuel-bounded reachability
- package closure evidence is carried through named properties:
  `PackageClosure.ReferencesResolve` and
  `PackageClosure.NoFuelBoundedCycles`
- strict artifact policy rejects raw check commands and raw build-script
  escape hatches before proof-carrying artifact emission

## Implemented Schemas

The schema layer is no longer just a single CLI shape.

Implemented:

- `CliProject`: package, default app, default dev shell, default check
- `MultiSystemCliProject`: one logical CLI project across multiple active
  systems
- `LibraryProject`: package-first library-style output with default dev shell
  and check conventions
- `MultiAppProject`: one package graph exposed through multiple apps
- `FormatterProject`: formatter output as a typed package reference
- `ServiceProject`: daemon-style package, default app, default dev shell, and
  one or more service checks
- `ValidatedSchema`: explicit boundary before schema lowering
- `Flake.fromSchema` and `Flake.fromValidatedSchema`: schema-to-validated-flake
  paths

Missing or still shallow:

- documentation or website schemas
- data-only/package-set schemas
- schema composition helpers for repeated package/app/check/dev-shell patterns
- schemas with policy knobs, such as "default app required" versus "all apps
  named"

## Rendering and Artifacts

Implemented:

- `ValidatedFlake` is the renderer boundary.
- Generated Nix emits active-system output blocks.
- Package and app defaults are synthesized where needed.
- Formatter outputs render as `formatter.${system}`.
- String escaping and attr-name quoting are handled.
- Fixed-output sources render through `builtins.fetchTree`.
- Development sources remain non-flake source inputs with trust-boundary
  comments.
- `emit-artifact` writes `flake.nix` and `leanix.manifest.json`.
- `emit-service-artifact` writes the second proof-carrying artifact shape from
  `ServiceProject`.
- Rust e2e performs the generic manifest preflight for generated files, file
  hashes, replay command metadata, input policy, and escape policy.
- `verify-artifact` remains as the showcase compatibility verifier.
- Artifact manifests record input trust classes, pin policy, rev/hash metadata,
  lockfile witness metadata, systems, packages, app/check references, checked
  invariants, replay commands, and active escape policy.
- Artifact verification rejects floating flake inputs without pinned ref or
  lockfile witness evidence.

Important boundary:

- The manifest is emitted by Lean code as JSON text, and the Rust preflight
  still parses only the manifest structure Leanix emits today rather than a
  complete JSON model.
- `verify-artifact` still has showcase-specific checks and should not be
  mistaken for a general artifact verifier. The Rust e2e preflight is the
  generic path and now covers both showcase and service artifacts.

## Rust E2E Harness

The Rust e2e harness in `e2e/runner` is central infrastructure.

It currently covers:

- rendering valid examples
- comparing selected generated flakes to goldens
- running `nix flake check path:./generated`
- proof-carrying artifact emission and verification
- tampered and missing generated-file artifact rejection
- floating input and lockfile-witness artifact policy cases
- strict artifact raw-check rejection
- checked per-system output evidence carried on `ValidatedFlake`
- invalid examples with exact stderr checks
- CLI example registry listing and generic rendering
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

Current parsed contracts cover selected input declarations, output families,
active systems, packages, apps, dev shells, checks, formatters, and selected
default aliases.

Next pressure:

- replace desugared JSON path/string checks with a dedicated parsed summary
  mode in `nixparserlean`
- add an artifact-flake interop case
- keep this as Rust-owned interop rather than a direct Lean dependency until the
  shared contract is more stable

## Near-Term Project Shape

Leanix is now past the first proof of concept. The next version should make the
system easier to extend and trust:

- package-set schemas for common non-CLI shapes
- keep the schema catalog reference maintained as schemas change
- build plans as the main package-authoring API for normal examples
- a Rust-owned generic artifact verifier
- stronger proof-carrying graph values and checked-output boundaries
- explicit interop contracts with generated Nix and artifact flakes
- a small Rust-owned user workflow for render-and-check commands
