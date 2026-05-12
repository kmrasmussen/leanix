# Roadmap

Status legend: ✅ done, 🟡 partial, ⬜ not started.

## Phase 0: Vocabulary — ✅

- ✅ Define systems, source pins, hashes, inputs, packages, apps, shells,
  checks, and flakes (`Leanix/Core.lean`).
- ✅ Keep the model pure. No subprocesses, no Nix store interaction in Lean.
- ✅ Add tiny example flakes as Lean values (`helloFlake`, `closureFlake`,
  `selfFlake`, `helloCliProject`, `showcaseCliProject` in
  `Leanix/Examples.lean`).

## Phase 1: Typed Output Schemas — 🟡

- ✅ Distinguish conventional flake outputs by type: `Package`, `App`,
  `DevShell`, `Check` are all indexed by `System`.
- ✅ Helpers for the conventional `default` output exist in the renderer
  (`renderPackageDefaults`, `renderAppDefaults`).
- ✅ Validate that every app/check/dev-shell entry references an existing
  package (`validateSystemOutputs`).
- ✅ First typed schema `CliProject` with proof-carrying `Valid` proposition
  and `ValidatedSchema` boundary (`Leanix/Schema.lean`).
- ✅ Synthetic default packages render as aliases to the first named package,
  matching the default-app shape.
- ✅ `MultiSystemCliProject` groups per-system `CliProject` values under one
  logical project name, validates each active system, and lowers to a
  `ValidatedFlake` with at least two active systems.
- ✅ `LibraryProject` models package-first library outputs with default
  dev-shell/check conventions.
- ✅ `MultiAppProject` models one package graph exposed through several app
  outputs.
- ✅ `FormatterProject` models formatter outputs as typed package references.
- ✅ `ServiceProject` models daemon-style package/app/dev-shell/check
  conventions.
- ✅ Maintained schema catalog reference in `docs/schema-catalog.md`.
- ⬜ Package-set and documentation-oriented schemas.

## Phase 2: Reproducibility Model — 🟡

- ✅ `validateInput` requires a `narHash` for fixed-output `Input.source` pins.
- ✅ `Input.source` renders as a `builtins.fetchTree` binding once hashed.
- ✅ Local sources are split into `Input.localDevSource` and
  `Input.impureLocalSource`; they are rendered as non-flake inputs with an
  explicit trust-boundary comment.
- ✅ Artifact manifests record flake input pin policy and pinned rev/hash
  metadata, and artifact verification rejects floating flake inputs without a
  lockfile witness.
- 🟡 Track builder identity and declared dependencies beyond the package graph:
  `BuildPlan` now names typed builder identities for known nixpkgs packages,
  executable text wrappers, input-tree/file copies, text-file installation,
  package executable runs, and Lean package builds from input trees, and
  exposes package/input references before lowering.
- 🟡 Model build plans separately from realized store paths: plans lower to the
  existing Nix-shaped `BuildExpr` backend in the first slice.
- ✅ Build-plan path validation rejects empty paths, parent traversal, absolute
  host paths, and output destinations outside `$out`.
- ✅ Validation returns structured `ValidateError` and `SchemaError` values.
- ✅ Proof-carrying artifacts record pinned input evidence or lockfile witness
  metadata, and strict artifact policy rejects raw check/build-script escape
  hatches.
- ⬜ CI policy and impure/local source policy matrix.

## Phase 3: Nix Interop — 🟡

- ✅ Render a restricted Leanix graph to a `flake.nix` via
  `Leanix/Render.lean`.
- ✅ The Rust e2e harness (`e2e/runner`) renders examples, runs
  `nix flake check path:./generated`, and golden-compares the showcase against
  `examples/proof-carrying-cli-closure/expected.flake.nix`.
- ✅ Renderer emits one output block per active system. The e2e harness covers
  a two-system package flake.
- ✅ Schema-level multi-system authoring is distinct from graph-level
  multi-system rendering: the renderer can emit any checked multi-system graph,
  while `MultiSystemCliProject` is the current typed authoring schema for one
  logical CLI project across systems.
- ✅ Build-expression depth exhaustion is reported as a Lean render error, not
  embedded as a generated Nix `throw`.
- ✅ Optional nixparserlean interop reads `--desugar --format json` for selected
  generated flakes, checks parsed-output contracts, and runs top-level `--eval`.
- 🟡 Round-trip shape checks cover selected inputs, output families, active
  systems, formatter outputs, and default aliases; a dedicated nixparserlean
  summary mode is still future work.
- ⬜ Artifact-flake interop case.

## Phase 4: Proofs — 🟡

- ✅ `CliProject.Valid` is a real `Prop` with concrete proof fields, populated
  by `CliProject.validateChecked`.
- ✅ `Flake.fromValidatedSchema` produces a `ValidatedFlake`, and `renderFlake`
  consumes that checked boundary instead of accepting raw `Flake` values.
- ✅ `CliProject.validate` and `CliProject.validateChecked` share the same
  witness-producing condition list.
- 🟡 `PackageClosure.Valid` carries named closure properties
  (`ReferencesResolve`, `NoFuelBoundedCycles`, and `NoTopologicalCycles`)
  instead of exposing only raw boolean equality fields; the current
  constructors are still backed by executable checkers.
- 🟡 `CheckCommand` provides a typed check-command surface with package/input
  reference validation while keeping `rawShell` as an explicit escape hatch.
- ✅ `EscapePolicy` distinguishes development from strict artifact contexts.
- ✅ `CheckedSystemOutputs` carries reusable per-system evidence for package
  graph validity plus app, dev-shell, check, and formatter references.
- ⬜ Prove that successful validation implies renderable output for the
  supported Nix backend subset.
- ⬜ Prove the topological checker's success means no package dependency cycles.
- ⬜ Prove system compatibility lemmas at the type level rather than only
  enforcing them by indexing.

## Phase 5: Proof-Carrying Artifacts — 🟡

The first showcase artifact exists: `leanix emit-artifact --out DIR` writes a
rendered `flake.nix` and `leanix.manifest.json` with source reference, checked
invariants, input trust classes, pin/lockfile evidence, file hashes, active
escape policy, and replay metadata.

- ✅ Rust e2e owns the generic artifact manifest preflight for generated files,
  file hashes, replay command metadata, input policy, and escape policy.
- ✅ `verify-artifact` remains as the showcase compatibility verifier.
- ✅ e2e covers tampered artifacts, missing generated files, floating input
  rejection, lockfile witness acceptance, and strict raw-check rejection.
- ✅ Multiple artifact examples: the CLI showcase artifact and the
  `ServiceProject` artifact both verify through the Rust generic preflight.

## Operational

- 🟡 Backlog lives under `.tickets/`; the active next wave is
  `TICKET-0034` through `TICKET-0044`.
- ✅ CI workflow exists in `.github/workflows/ci.yml`.
- ✅ Source trust modeling is represented by `Input.source`,
  `Input.localDevSource`, and `Input.impureLocalSource`.
- ✅ CLI example registry exists via `leanix list-examples` and
  `leanix render NAME --out FILE`.
- ⬜ Focused render-and-check workflow and e2e filters.
