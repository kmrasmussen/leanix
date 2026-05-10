# TICKET-0009: Validated Render Boundary

## Problem
Leanix advertises a "proof-carrying" path from typed value to rendered flake,
but the proof is currently a marker that the renderer does not consume.

Three concrete symptoms:

1. `ValidatedSchema.valid` exists, but `Flake.fromValidatedSchema` discards
   it. The renderer takes a plain `Flake` and re-runs `validateFlake` at
   render time, so a "validated schema" gives no guarantee about whether the
   resulting flake will render.
2. `CliProject.validate` and `CliProject.validateChecked` are independent
   runtime checks with the same six conditions, written twice. Nothing in the
   type system keeps them in sync; a future condition added to one and
   forgotten in the other passes silently.
3. There is no `ValidatedFlake` boundary. Three paths exist
   (`Flake.fromSchema`, `Flake.fromValidatedSchema`, raw `Flake`), and only
   the renderer's internal `validateFlake` call always runs. That makes the
   renderer the de facto truth, even though its name says it renders.

This is what makes the "proof-carrying" claim shallow: nothing downstream
depends on the proof, so the proof being correct doesn't change behavior.

## Goal
Make the validated-schema and validated-flake boundaries load-bearing.

A successful render path should look like:

```text
schema -> ValidatedSchema schema -> ValidatedFlake -> rendered flake.nix
```

with each arrow either a function whose existence requires the previous
witness, or a function that produces a stronger witness.

## In Scope
- A `ValidatedFlake` wrapper type carrying `Flake` plus evidence
  (proposition or decidable bundle) that `validateFlake` succeeds.
- A renderer entry point that consumes `ValidatedFlake` and does not re-run
  `validateFlake` internally.
- A construction that consumes `ValidatedSchema schema` and produces
  `ValidatedFlake` for the relevant schema, threading the schema's
  `Valid` fields into the flake-level evidence where they correspond.
- A single source of truth for `CliProject.validate`: define it via
  `validateChecked` (or define `validateChecked` via decidable predicates
  from `validate`), so both paths use the same checks.
- A Rust e2e case that proves the new boundary by trying to render an
  unvalidated `Flake` from CLI/test code and confirming the type system
  refuses, or that the supported CLI surface always goes through the
  boundary.

## Out of Scope
- Replacing `Except String Unit` with structured errors (TICKET-0002).
- Proving renderer correctness from `ValidatedFlake` (TICKET-0003 covers
  package-graph proof; renderer correctness is a later milestone).
- Strengthening `CliProject.Valid` itself with more conditions.

## Acceptance Criteria
1. The supported render path takes a `ValidatedFlake` (or equivalent
   evidence-carrying value); `Flake` alone cannot reach `renderFlake`'s
   inner pipeline without going through validation.
2. `CliProject.validate` and `CliProject.validateChecked` share their
   condition list — adding a check to one is a compile error or test
   failure in the other.
3. `Flake.fromValidatedSchema` produces a `ValidatedFlake`, not a raw
   `Flake`; the schema-level proofs feed into at least one flake-level
   evidence field.
4. `lake build` and the Rust e2e harness still pass.

## First Slice
1. Define `ValidatedFlake` and a smart constructor that runs
   `validateFlake` and returns evidence on success.
2. Make `renderFlake` accept `ValidatedFlake` and delete the
   `validateFlake` call from inside it.
3. Update `Flake.fromValidatedSchema` and `Flake.fromSchema` to return
   `ValidatedFlake`.
4. Migrate `Main.lean`'s render commands.

Keep `CliProject.validate` / `validateChecked` deduplication for a follow-up
commit; the boundary type is the load-bearing change.

## Progress

- Added `ValidatedFlake` plus `Flake.validateChecked`, carrying
  `validateFlake flake = .ok ()` and a list of carried invariant labels.
- Changed `renderFlake` to consume `ValidatedFlake`; raw `Flake` values now
  stop at CLI adapter helpers unless they pass through validation first.
- Changed `Flake.fromValidatedSchema` and `Flake.fromSchema` to return
  `ValidatedFlake`, threading `FlakeSchema.Valid` into the carried invariant
  list.
- Deduplicated `CliProject.validate` and `CliProject.validateChecked` through
  `CliProject.validateEvidence`, a single witness-producing condition list.
- Updated the PoC, roadmap, and vision notes to describe the load-bearing
  validated render boundary.
