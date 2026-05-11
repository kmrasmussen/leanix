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
- ⬜ Formatter-oriented schemas.

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
  executable text wrappers, and input-tree copies, and exposes package/input
  references before lowering.
- 🟡 Model build plans separately from realized store paths: plans lower to the
  existing Nix-shaped `BuildExpr` backend in the first slice.
- ✅ Validation returns structured `ValidateError` and `SchemaError` values.

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
- ⬜ Read parsed Nix from `nixparserlean` for comparison.
- ⬜ Round-trip check: parse the rendered flake back and assert preservation of
  the typed output schema.

## Phase 4: Proofs — 🟡

- ✅ `CliProject.Valid` is a real `Prop` with concrete proof fields, populated
  by `CliProject.validateChecked`.
- ✅ `Flake.fromValidatedSchema` produces a `ValidatedFlake`, and `renderFlake`
  consumes that checked boundary instead of accepting raw `Flake` values.
- ✅ `CliProject.validate` and `CliProject.validateChecked` share the same
  witness-producing condition list.
- ⬜ Prove that successful validation implies renderable output for the
  supported Nix backend subset.
- ⬜ Prove `validateNoPackageCycles` is sound and complete (it is fuel-bounded
  reachability today).
- ⬜ Prove system compatibility lemmas at the type level rather than only
  enforcing them by indexing.

## Phase 5: Proof-Carrying Artifacts — 🟡

The first showcase artifact exists: `leanix emit-artifact --out DIR` writes a
rendered `flake.nix` and `leanix.manifest.json` with source reference, checked
invariants, input trust classes, and replay metadata.

## Operational

- 🟡 Backlog lives under `.tickets/`.
- ✅ CI workflow exists in `.github/workflows/ci.yml`.
- ✅ Source trust modeling is represented by `Input.source`,
  `Input.localDevSource`, and `Input.impureLocalSource`.
