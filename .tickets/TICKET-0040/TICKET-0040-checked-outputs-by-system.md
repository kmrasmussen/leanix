# TICKET-0040: Checked Outputs By System

## Roadmap Source
This ticket materializes the checked-output boundary slice from:

- `roadmap/02-milestones.md` Milestone 4: Package Closure Proof V2
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0040
- `roadmap/06-open-questions.md` What Is the Right Proof Target for Package Closure?

## Problem
`ValidatedFlake` validates whole flakes, but the proof/evidence boundary does
not expose a reusable checked-output value per system. This makes it harder for
schemas, renderers, and artifacts to point at precise checked facts.

## Goal
Introduce a checked per-system output boundary that can carry package graph,
app, shell, check, and formatter reference evidence.

## In Scope
- Define `CheckedSystemOutputs` or equivalent.
- Populate it during validation.
- Expose named evidence for package references, app/check/shell references, and
  formatter references.
- Keep renderer behavior unchanged in the first slice.
- Document how this relates to `ValidatedFlake`.

## Out of Scope
- Full renderer refactor.
- Proving Nix evaluation behavior.
- Replacing schema validation.

## Acceptance Criteria
1. Validation produces reusable checked-output evidence.
2. Examples still elaborate without brittle proof terms.
3. Artifact invariant names can point at the checked-output boundary.
4. Existing e2e cases pass unchanged or with intentional manifest updates.
5. Docs explain the new boundary.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Validate.lean`
- `Leanix/Artifact.lean`
- `docs/poc.md`
- `docs/closure-proof-strategy.md`
- `blog/yyyy-mm-dd-hh-mm-checked-outputs-by-system.md`

## Progress
- Not started.
