# TICKET-0027: BuildPlan Install File and Copy Source Constructors

## Roadmap Source
This ticket materializes the next build-plan authoring slice from:

- `roadmap/02-milestones.md` Milestone 2: BuildPlan V2
- `roadmap/03-workstreams.md` Workstream A: Typed Authoring Surface
- `roadmap/04-ticket-wave.md` TICKET-0027

## Problem
`BuildPlan` now exists, but common package authoring still drops into backend
`BuildExpr` or lower-level `BuildStep` values for operations Leanix should own
semantically.

The model should make routine source and file installation operations visible
before lowering to Nix.

## Goal
Move common file/source operations into typed `BuildPlan` constructors with
named arguments, validation, and e2e coverage.

## In Scope
- Add build-plan constructors for installing text files.
- Add build-plan constructors for copying source files or source trees.
- Migrate at least one package from direct `BuildExpr.runSteps` authoring to a
  typed build plan.
- Validate package, input, and source references before lowering.
- Add one invalid e2e case for a missing input or source reference.
- Keep the existing backend `BuildStep` lowering readable.

## Out of Scope
- Replacing every `BuildExpr` use.
- Modeling a full file operation DSL.
- Implementing tarball unpacking or language-specific build systems.
- Changing artifact policy behavior.

## Dependencies
- Builds on `TICKET-0020` typed build plans.
- Builds on `TICKET-0025` typed check and structured build-step work.

## Implementation Notes
- Keep the build-plan constructors backend-neutral in names and intent.
- Lower to the existing renderer surface unless a renderer change is simpler
  and well covered.
- Prefer exact validation errors over permissive lowering.
- Preserve generated golden fixtures unless the generated Nix becomes clearly
  better and the change is documented.

## Acceptance Criteria
1. At least one package is authored entirely through `BuildPlan` constructors
   instead of direct `BuildExpr.runSteps`.
2. Missing input or source references inside a plan fail validation before
   rendering.
3. The invalid e2e case checks exact stderr.
4. Existing generated flakes remain stable or change with a documented reason.
5. Build-plan docs describe which operations are semantic and which remain
   backend-specific.

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
- `blog/yyyy-mm-dd-hh-mm-build-plan-file-constructors.md`

## Progress
- Not started.
