# TICKET-0037: BuildPlan Path and Destination Validation

## Roadmap Source
This ticket materializes the validation slice from:

- `roadmap/02-milestones.md` Milestone 2: BuildPlan V2
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0037
- `roadmap/06-open-questions.md` How Far Should BuildPlan Move Away From Nix?

## Problem
Build-plan argument records expose destinations and paths, but Leanix does not
yet validate basic path hazards. That leaves common mistakes to the generated
Nix backend or build-time failures.

## Goal
Add conservative authoring-time validation for build-plan paths and
destinations.

## In Scope
- Define simple path rules for build-plan destinations and source paths.
- Reject empty paths.
- Reject parent traversal where practical.
- Reject absolute host destinations where the plan expects store-output paths.
- Add exact stderr e2e cases.
- Document the boundary between authoring validation and filesystem security.

## Out of Scope
- A full path-normalization library.
- Filesystem sandbox/security modeling.
- Rewriting existing build-step rendering.

## Acceptance Criteria
1. Invalid path examples fail before rendering.
2. Valid existing build-plan examples still pass.
3. Exact stderr e2e covers at least two rejected path forms.
4. Docs state which path forms are accepted and why.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-build-plan-path-validation.md`

## Progress
- Not started.
