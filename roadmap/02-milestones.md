# Future Milestones

The roadmap is organized as milestones that can become ticket waves. Each
milestone should be small enough to land with documentation, e2e coverage, a
blog note, and a commit.

This file reflects the state after `TICKET-0035`. Completed slices remain
important context, and the remaining concrete backlog is `TICKET-0036` through
`TICKET-0044` in `roadmap/04-ticket-wave.md`.

## Milestone 1: Schema Catalog V2

Goal: make Leanix useful for more than CLI demos without creating a universal
schema language.

Already landed:

- `CliProject`, `MultiSystemCliProject`, `LibraryProject`, `MultiAppProject`,
  `FormatterProject`, and `ServiceProject`
- valid examples, invalid e2e cases, and goldens for the current schema set
- schema catalog reference docs that explain when to use each schema

Next deliverables:

- shared schema helper extraction only where repeated conventions justify it

Acceptance checks:

- new schemas lower through `ValidatedSchema`
- invalid schema errors name the violated convention
- examples pass `nix flake check`
- docs clearly describe schema choice

## Milestone 2: BuildPlan V2

Goal: make build plans the normal package authoring surface.

Already landed:

- typed build-plan constructors for known nixpkgs packages, executable text
  wrappers, input tree/file copies, text-file installation, running package
  executables, and building Lean packages from input trees
- validation for duplicate args and missing source/input/package references
- conservative path/destination validation for build-plan argument records
- multiple examples using `Package.fromBuildPlan`

Next deliverables:

- clearer package dependency extraction from build plans before lowering
- more examples migrated away from direct `BuildExpr.runSteps`

Acceptance checks:

- at least two additional examples use `Package.fromBuildPlan`
- generated goldens stay stable or intentionally change with explanation
- invalid plan cases have exact stderr e2e tests

## Milestone 3: Artifact Manifest V2

Goal: make artifacts verifiable beyond the showcase hard-coded contract.

Already landed:

- manifest-driven generated-file checks
- file hash recording and tamper rejection
- lockfile witness metadata
- strict artifact escape policy
- input policy rejection cases

Next deliverables:

- Rust-owned generic artifact verifier
- multiple artifact examples
- manifest schema/version reference docs
- replay command execution from manifest data rather than showcase-specific
  expectations

Acceptance checks:

- at least two artifact directories can be emitted and verified
- verifier rejects tampered and missing generated files
- verifier rejects missing or mismatched manifest fields
- development render commands remain unchanged

## Milestone 4: Package Closure Proof V2

Goal: connect package closure evidence to a clearer graph property.

Already landed:

- explicit package graph relation over package names
- named package closure properties for reference resolution and fuel-bounded
  cycle rejection

Next deliverables:

- topological or proof-friendlier cycle checker
- lemmas connecting successful checks to named graph properties
- checked per-system output evidence
- updated proof strategy docs

Acceptance checks:

- `CheckedPackageGraph` examples elaborate without brittle proof terms
- invalid cycle e2e remains exact
- proof names in artifact manifest stay meaningful

## Milestone 5: NixParserLean Contract V2

Goal: replace fragile parsed-Nix string checks with a meaningful contract.

Already landed:

- parsed-contract checks for selected generated examples
- input declarations, output families, systems, formatters, and selected
  default aliases in the optional interop lane
- docs that state the parse/desugar/top-level eval boundary

Next deliverables:

- dedicated summary mode in `nixparserlean`, or a stable JSON subset that is
  less path/string-fragment driven
- artifact-flake interop case
- better stale sibling-checkout reporting

Acceptance checks:

- `cargo run ... -- --nixparserlean-dir ../nixparserlean` verifies the richer
  contract
- interop docs clearly state parse/desugar/eval boundaries
- generated files remain ephemeral under `generated/`

## Milestone 6: CLI and Developer Experience

Goal: make Leanix easier to use without weakening the model.

Already landed:

- `leanix list-examples`
- generic `leanix render NAME --out FILE`
- compatibility preservation for old `render-*` commands
- registry e2e coverage

Next deliverables:

- focused render-and-check workflow, likely Rust-owned
- e2e case filters for faster development loops
- better structured CLI/help output if the current Lean command grows too much
- docs that map examples, checks, and proof boundaries

Acceptance checks:

- old commands continue working unless intentionally deprecated
- e2e covers new user-facing command paths
- subprocess orchestration stays in Rust unless there is a strong reason

## Milestone 7: Policy Layer

Goal: make reproducibility, trust, and escape-hatch policies explicit.

Already landed:

- development and strict artifact escape policies
- artifact manifests record active escape policy
- strict artifact policy rejects raw check/build-script escape hatches
- artifact input policy rejects unsupported floating refs

Next deliverables:

- CI policy value or policy record
- explicit behavior for floating flake refs, impure local sources, raw shell,
  and missing artifact evidence across development, CI, and strict artifact
  contexts
- e2e coverage for at least one policy rejection per policy class

Acceptance checks:

- development examples stay ergonomic
- CI/artifact examples are stricter where documented
- e2e covers policy rejections with exact stderr
