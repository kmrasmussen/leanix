# Proposed Next Ticket Wave

This is the next candidate backlog wave after the completed `TICKET-0033`
state. The previous wave, `TICKET-0026` through `TICKET-0033`, has been
materialized and completed. This wave focuses on the pressure that remains in
the roadmap: richer schemas, deeper build plans, a Rust-owned artifact verifier,
stronger graph/proof boundaries, better interop, and policy/CLI follow-through.

## TICKET-0034: Service Schema

Problem:

Leanix has CLI, library, multi-app, multi-system, and formatter schemas, but it
does not yet model service-like projects or daemon-style apps.

Goal:

Add a small service-oriented schema that exposes one package, one app entry, a
dev shell, and one or more checks around a daemon command.

Scope:

- define a concrete `ServiceProject` or equivalent
- validate service app/check package references and naming conventions
- render one valid service example with a golden fixture
- add one invalid schema convention e2e case
- document when to use a service schema instead of `CliProject` or raw `Flake`

Acceptance:

- service schema lowers through `ValidatedSchema`
- generated flake passes `nix flake check`
- invalid service schema error names the violated convention

## TICKET-0035: Schema Catalog Reference

Problem:

Schemas have grown organically, and `docs/poc.md` plus blog notes are no
longer enough as a stable reference.

Goal:

Add a maintained schema catalog that explains available schemas, their
contracts, examples, escape hatches, and when to drop to raw graph values.

Scope:

- add `docs/schema-catalog.md`
- include `CliProject`, `MultiSystemCliProject`, `LibraryProject`,
  `MultiAppProject`, `FormatterProject`, and any new service schema if present
- map each schema to examples and CLI registry names
- explain shared validation conventions and policy boundaries
- add a "raw Flake remains valid when..." section

Acceptance:

- docs describe every implemented schema
- README/examples docs link to the catalog
- the catalog reflects current code, not speculative future shapes

## TICKET-0036: BuildPlan Run Executable and Lean Package Constructors

Problem:

`BuildPlan` covers several file/source cases, but common package authoring still
falls back to backend-shaped `BuildExpr.runSteps`.

Goal:

Add build-plan constructors for running a package executable into an output and
building a Lean package from a source/input tree.

Scope:

- add named-argument build-plan constructors for executable-run and Lean build
  package cases
- lower them to the existing backend representation
- validate package/input references before lowering
- migrate at least one example currently using direct `BuildExpr.runSteps`
- add invalid e2e cases for missing package/input references

Acceptance:

- at least one additional example is authored through `Package.fromBuildPlan`
- generated golden changes are intentional and documented
- invalid plan failures have exact stderr e2e coverage

## TICKET-0037: BuildPlan Path and Destination Validation

Problem:

Build-plan argument records expose destinations and paths, but Leanix does not
yet validate basic path hazards.

Goal:

Add conservative validation for build-plan paths and destinations.

Scope:

- define simple path rules for build-plan destinations and source paths
- reject empty paths, absolute host destinations where not intended, and parent
  traversal where practical
- add exact stderr e2e cases
- document the boundary: this is authoring validation, not a full filesystem
  security model

Acceptance:

- invalid path examples fail before rendering
- valid existing build-plan examples still pass
- docs state which path forms are accepted and why

## TICKET-0038: Rust Artifact Verifier

Problem:

`verify-artifact` still lives in the Lean CLI and uses simple string/line
checks. That is increasingly mismatched with the roadmap principle that Rust
owns filesystem and manifest verification workflows.

Goal:

Move generic artifact verification into Rust while preserving the existing
Lean-emitted artifact format.

Scope:

- add a Rust-owned verifier path in the e2e runner or a small Rust CLI helper
- parse enough manifest structure without adding external crates unless needed
- verify generated files, file hashes, replay command list, input policy, and
  escape policy from manifest data
- keep `leanix verify-artifact` working as a compatibility wrapper or document
  the transition
- add e2e coverage for success and tamper/missing-file failures

Acceptance:

- Rust verifier can verify the showcase artifact
- Rust verifier rejects tampered and missing generated files
- docs clearly state which verifier is authoritative

## TICKET-0039: Multiple Artifact Examples

Problem:

Artifact emission and verification are still centered on the proof-carrying CLI
showcase.

Goal:

Add at least one second artifact shape so verifier work is not accidentally
showcase-specific.

Scope:

- define a second artifact emitter, likely for a formatter or service schema
- generate a manifest from checked values
- verify both artifacts in e2e
- ensure manifest fields are not hard-coded to the CLI showcase
- add docs explaining artifact variants

Acceptance:

- two artifact directories can be emitted and verified
- artifact manifests differ where their schema/output shape differs
- verifier failures remain exact and actionable

## TICKET-0040: Checked Outputs By System

Problem:

`ValidatedFlake` validates whole flakes, but the proof/evidence boundary does
not expose a reusable checked-output value per system.

Goal:

Introduce a checked per-system output boundary that can carry package graph,
app, shell, check, and formatter reference evidence.

Scope:

- define `CheckedSystemOutputs` or equivalent
- populate it during validation
- expose named evidence for package references, app/check/shell references, and
  formatter references
- keep renderer behavior unchanged in the first slice
- document how this relates to `ValidatedFlake`

Acceptance:

- validation produces reusable checked-output evidence
- examples still elaborate without brittle proof terms
- artifact invariant names can point at the checked-output boundary

## TICKET-0041: Topological Package Closure Checker

Problem:

Package cycle rejection is still fuel-bounded reachability. It works, but the
proof story remains indirect.

Goal:

Prototype a proof-friendlier topological package graph checker.

Scope:

- define a topological ordering or remove-ready-nodes algorithm over package
  names
- connect success to named acyclicity evidence
- preserve missing-reference and cycle error quality
- keep the existing cycle e2e exact, or intentionally update it with a better
  message
- write/update proof strategy docs

Acceptance:

- `CheckedPackageGraph` carries clearer acyclicity evidence
- invalid cycle e2e remains covered
- docs explain what is proven versus still checker-backed

## TICKET-0042: NixParserLean Artifact Interop

Problem:

The optional nixparserlean interop suite checks generated examples, but not the
proof-carrying artifact flake itself.

Goal:

Add an artifact-flake interop case and tighten the parsed contract around
artifact output shape.

Scope:

- render an artifact under `generated/`
- run nixparserlean `--desugar --format json` and `--eval` against the artifact
  `flake.nix`
- check input declarations, output families, default aliases, and pinned-input
  shape where visible to the parser
- document that this is still parse/desugar/top-level eval, not full semantic
  equivalence

Acceptance:

- `--nixparserlean-dir` e2e covers the artifact flake
- interop docs describe the artifact case and its boundary
- generated interop files remain ignored under `generated/`

## TICKET-0043: CLI Check Command and E2E Filters

Problem:

`leanix render NAME --out FILE` improves discovery, but checking still requires
manual `nix flake check` or the full Rust e2e harness.

Goal:

Add a Rust-owned workflow for focused render-and-check usage, plus e2e filters
for faster development loops.

Scope:

- decide whether this is a Rust helper binary or an extension of the e2e runner
- add a command/filter for running one or a subset of cases
- support render plus `nix flake check` for a named registry example
- keep Lean focused on pure rendering
- document the workflow

Acceptance:

- one named example can be checked without running the whole suite
- full e2e remains the default gate
- docs explain when to use focused checks

## TICKET-0044: Policy Matrix for CI and Impure Sources

Problem:

Leanix now has development and strict artifact escape policies, plus input pin
policy, but there is no coherent matrix for CI and impure/local source rules.

Goal:

Define a small policy matrix for development, CI, and strict artifact contexts.

Scope:

- extend policy values or add a policy record for CI
- define behavior for floating flake refs, impure local sources, raw shell, and
  missing artifact evidence
- add e2e rejection cases for at least one CI-only or artifact-only rule
- keep development examples ergonomic
- update docs and manifests where policy is recorded

Acceptance:

- policy behavior is explicit in code and docs
- at least one impure/local source policy rejection has exact stderr coverage
- artifact manifests still record the active policy
