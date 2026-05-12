# Workstreams

This file groups future work by engineering track. Milestones can draw from
multiple workstreams, but each workstream has a distinct owner boundary.

## Workstream A: Typed Authoring Surface

Purpose: make common flake shapes concise, typed, and validated before backend
rendering.

Current assets:

- `CliProject`
- `MultiSystemCliProject`
- `LibraryProject`
- `MultiAppProject`
- `FormatterProject`
- `ServiceProject`
- `ValidatedSchema`
- `BuildPlan`
- `CheckCommand`
- `docs/schema-catalog.md`

Next work:

- package-set or data-only schema
- schema composition helpers only where repeated patterns justify them
- richer build-plan constructors
- fewer example packages authored directly as `BuildExpr`

Risks:

- adding schemas too quickly without real examples
- turning schemas into a weak universal DSL
- duplicating validation logic across schemas

Guardrail:

- every schema must have a valid example, an invalid e2e case, and docs saying
  when to drop to raw graph values.

## Workstream B: Validation and Proof Evidence

Purpose: ensure Leanix's type and proof boundaries express real graph
invariants.

Current assets:

- structured `ValidateError` and `SchemaError`
- `ValidatedFlake`
- `ValidatedSchema`
- `CheckedPackageGraph`
- `PackageClosure.ReferencesResolve`
- `PackageClosure.NoFuelBoundedCycles`
- strict/development escape policy validation

Next work:

- checked outputs per system
- prove reference-resolution helper lemmas
- replace or supplement fuel-bounded cycle evidence with a clearer graph proof
- connect schema validity to graph validity more explicitly
- make proof-carrying artifact invariant names generated from checked
  structures instead of maintained as a manual list

Risks:

- brittle proof terms in examples
- proof work that does not change user-facing confidence
- overstating the proof as Nix evaluation correctness

Guardrail:

- proof work should have one of these visible effects: stricter validation,
  clearer manifest evidence, simpler examples, or a removed runtime check.

## Workstream C: Backend Rendering

Purpose: keep Nix as a reliable backend without letting it become the source of
truth.

Current assets:

- `renderFlake`
- active-system output blocks
- defaults for packages/apps
- formatter output rendering
- quoted attr names and escaped strings
- fixed-output source rendering
- generated golden fixtures

Next work:

- renderer errors with better context
- service/app rendering conventions
- optional metadata for apps/checks
- backend-neutral build-plan lowering API
- renderer support for richer artifact manifests

Risks:

- renderer drift from validation assumptions
- generated Nix becoming too clever to inspect
- adding Nix-specific concepts to the authoring model too early

Guardrail:

- every renderer change should have a golden or parsed-contract check.

## Workstream D: Proof-Carrying Artifacts

Purpose: make generated artifact directories useful and verifiable.

Current assets:

- `emit-artifact`
- `verify-artifact`
- `leanix.manifest.json`
- pinned input metadata
- lockfile witness metadata
- file hash recording and tamper detection
- replay commands
- strict artifact escape policy

Next work:

- Rust-owned generic artifact verifier
- multiple artifact examples
- manifest schema docs
- replay command execution from manifest data rather than showcase-specific
  checks
- stricter policy matrix for CI/artifact contexts

Risks:

- hard-coded showcase verifier growing too far
- hand-rolled JSON becoming fragile
- manifest claims not tied to checked Lean values

Guardrail:

- if a manifest field is a claim, either the verifier checks it or the docs
  mark it informational.

## Workstream E: Rust Harness and Tooling

Purpose: keep effects, subprocesses, and filesystem workflows outside Lean.

Current assets:

- no-dependency Rust e2e runner
- generated flake checks
- exact stderr checks
- artifact replay and tamper fixtures
- CLI registry coverage
- optional nixparserlean interop

Next work:

- split e2e runner into modules once it becomes too large
- add command-line filters for cases
- add a focused render-and-check workflow
- add structured summary output for CI logs
- possibly add a Rust CLI wrapper if user workflows outgrow Lean's executable

Risks:

- a monolithic `main.rs` becoming hard to maintain
- adding dependencies before the harness shape stabilizes
- slow e2e runs discouraging frequent checks

Guardrail:

- keep the default full e2e meaningful, but allow focused subsets for active
  development.

## Workstream F: NixParserLean Interop

Purpose: use `nixparserlean` as independent feedback on generated Nix syntax and
shape.

Current assets:

- optional `--nixparserlean-dir`
- parsed contract checks for selected cases
- `--desugar --format json`
- `--eval` top-level record check
- formatter/default-alias/input declaration checks in selected contracts

Next work:

- stable parsed summary contract
- artifact flake interop case
- source/pin shape checks where visible to the parser
- explicit report when nixparserlean build state is stale

Risks:

- confusing parse/desugar/eval with full semantic interop
- making Leanix depend directly on a volatile sibling checkout
- using generated files as source artifacts

Guardrail:

- interop docs should always state exactly what was checked.

## Workstream G: Documentation and Project Narrative

Purpose: keep the project understandable as it grows.

Current assets:

- `README.md`
- `docs/poc.md`
- `docs/roadmap.md`
- dated blog notes
- examples README
- this roadmap folder
- CLI example registry docs

Next work:

- architecture diagram in text form
- schema catalog reference
- build-plan reference
- artifact manifest reference
- proof boundary reference
- "how to add a new example" guide

Risks:

- docs repeating stale implementation details
- blog notes substituting for maintained reference docs

Guardrail:

- blog notes narrate progress; docs describe current truth.
