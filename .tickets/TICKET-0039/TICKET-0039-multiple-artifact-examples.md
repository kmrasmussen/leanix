# TICKET-0039: Multiple Artifact Examples

## Roadmap Source
This ticket materializes the artifact breadth slice from:

- `roadmap/02-milestones.md` Milestone 3: Artifact Manifest V2
- `roadmap/03-workstreams.md` Workstream D: Proof-Carrying Artifacts
- `roadmap/04-ticket-wave.md` TICKET-0039
- `roadmap/06-open-questions.md` Where Should Artifact Verification Live?

## Problem
Artifact emission and verification are still centered on the proof-carrying CLI
showcase. That makes it easy for verifier behavior and manifest fields to
remain accidentally showcase-specific.

## Goal
Add at least one second artifact shape so verifier work is not accidentally tied
to the CLI showcase.

## In Scope
- Define a second artifact emitter, likely for a formatter or service schema.
- Generate a manifest from checked values.
- Verify both artifacts in e2e.
- Ensure manifest fields are not hard-coded to the CLI showcase.
- Add docs explaining artifact variants.

## Out of Scope
- Artifact publishing or distribution.
- General artifact templates.
- Replacing the showcase artifact.

## Acceptance Criteria
1. Two artifact directories can be emitted and verified.
2. Artifact manifests differ where their schema/output shape differs.
3. The verifier does not hard-code all checks to the CLI showcase.
4. Failure messages remain exact and actionable.
5. Docs describe current artifact variants.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Artifact.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-multiple-artifact-examples.md`

## Progress
- Completed in this ticket.

## Plan
1. Add a second strict artifact emitter using an existing non-CLI schema.
2. Make its manifest differ at the source, output, and checked-invariant level.
3. Verify both artifact shapes through the Rust generic artifact preflight.
4. Update docs so the artifact boundary is no longer described as showcase-only.

## Result
- Added `leanix emit-service-artifact --out DIR`, backed by
  `ServiceProject.validate` and strict artifact policy.
- Added a service artifact manifest with `ServiceProject.*` invariant evidence,
  a `health` check, and service-specific source reference.
- Extended the Rust e2e artifact case to emit and verify both the showcase and
  service artifacts with the same generic preflight.
- Updated PoC, roadmap, examples, and verification strategy docs.

## Verification Result
- Passed: `nix develop --command lake build`.
- Passed: `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`.
