# Future Milestones

The roadmap is organized as milestones that can become ticket waves. Each
milestone should be small enough to land with documentation, e2e coverage, a
blog note, and a commit.

## Milestone 1: Schema Catalog V1

Goal: make Leanix useful for more than CLI demos without creating a universal
schema language.

Deliverables:

- `FormatterProject` or formatter extension for existing schemas
- one service-style app schema or daemon-oriented schema
- schema docs that explain when to use `CliProject`, `LibraryProject`,
  `MultiAppProject`, and raw `Flake`
- invalid e2e cases for each new schema convention
- golden fixtures for valid examples

Acceptance checks:

- new schema lowers through `ValidatedSchema`
- invalid schema errors name the violated convention
- examples pass `nix flake check`
- docs clearly describe the schema choice

Likely files:

- `Leanix/Schema.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `e2e/golden/*.flake.nix`
- `docs/poc.md`
- `examples/README.md`

## Milestone 2: BuildPlan V2

Goal: make build plans the normal package authoring surface.

Deliverables:

- migrate more packages from direct `BuildExpr` to `BuildPlan`
- add typed build-plan constructors for common operations:
  - install text file
  - copy fixed-output source
  - run package executable
  - build Lean package from input tree
- add build-plan validation for:
  - duplicate args
  - invalid destination paths where practical
  - missing source/input/package references
- make package dependencies available from build plans before lowering

Acceptance checks:

- at least two existing examples use `Package.fromBuildPlan`
- generated goldens stay stable or intentionally change with explanation
- invalid plan cases have exact stderr e2e tests

Likely files:

- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `e2e/runner/src/main.rs`

## Milestone 3: Artifact Manifest V2

Goal: make artifacts verifiable beyond the showcase hard-coded contract.

Deliverables:

- manifest parser or structured verifier in Rust
- per-file hashes for generated files
- replay command list execution from manifest data rather than hard-coded
  showcase expectations
- manifest schema versioning rules
- lockfile witness field that can justify lockfile-backed flake inputs
- negative tests for mismatched file hashes, missing generated files, and
  unsupported input policy

Acceptance checks:

- `verify-artifact DIR` can verify at least two artifact directories
- verifier rejects a tampered `flake.nix`
- verifier rejects a missing or mismatched manifest field
- development render commands remain unchanged

Likely files:

- `Leanix/Artifact.lean`
- `Main.lean` for transitional CLI behavior
- `e2e/runner/src/main.rs`
- future `e2e/artifact-fixtures/`

## Milestone 4: Package Closure Proof V2

Goal: connect package closure evidence to a clearer graph property.

Deliverables:

- explicit package graph relation over package names
- proof-friendly reachability or topological sort model
- lemma from successful checker to `ReferencesResolve`
- lemma from successful checker to `NoFuelBoundedCycles`, or a replacement
  checker with a cleaner proof story
- updated proof strategy docs

Acceptance checks:

- `CheckedPackageGraph` examples elaborate without brittle proof terms
- invalid cycle e2e remains exact
- proof names in artifact manifest stay meaningful

Likely files:

- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `docs/closure-proof-strategy.md`

## Milestone 5: NixParserLean Contract V2

Goal: replace fragile parsed-Nix string checks with a meaningful contract.

Deliverables:

- a richer parsed summary mode in `nixparserlean`, or a stable JSON subset
  consumed by Leanix
- contracts for:
  - output families
  - active systems
  - package/app/check references
  - default aliases
  - input declarations
- optional fixture for generated artifact flake

Acceptance checks:

- `cargo run ... -- --nixparserlean-dir ../nixparserlean` verifies the richer
  contract
- interop docs clearly state parse/desugar/eval boundaries
- generated files remain ephemeral under `generated/`

Likely files:

- `e2e/runner/src/main.rs`
- `interop/nixparserlean/README.md`
- possibly sibling `nixparserlean` changes

## Milestone 6: CLI and Developer Experience

Goal: make Leanix easier to use without weakening the model.

Deliverables:

- `leanix list-examples`
- `leanix render EXAMPLE --out FILE` instead of many ad hoc commands, if it
  can stay simple
- `leanix check EXAMPLE` to render then run `nix flake check`, likely Rust-owned
  if subprocess orchestration grows
- better CLI help output
- docs that map examples to commands and proof boundaries

Acceptance checks:

- old commands either continue working or are intentionally deprecated
- e2e covers the new user-facing command path
- no subprocess orchestration is moved into Lean unless there is a strong reason

## Milestone 7: Policy Layer

Goal: make reproducibility, trust, and escape-hatch policies explicit.

Deliverables:

- policy values for development, CI, and proof-carrying artifact contexts
- validation that can vary by policy:
  - floating flake refs allowed or rejected
  - raw shell allowed, warned, or rejected
  - impure local sources allowed or rejected
  - missing artifact evidence rejected
- manifest records the active policy

Acceptance checks:

- development examples stay ergonomic
- artifact examples are strict
- e2e covers at least one policy rejection per policy class
