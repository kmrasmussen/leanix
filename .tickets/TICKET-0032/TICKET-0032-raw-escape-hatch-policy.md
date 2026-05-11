# TICKET-0032: Raw Escape Hatch Policy

## Roadmap Source
This ticket materializes the policy-layer slice from:

- `roadmap/02-milestones.md` Milestone 7: Policy Layer
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0032
- `roadmap/06-open-questions.md` How Strict Should Artifact Policy Be?

## Problem
Raw shell and raw graph escape hatches are explicit, but every context currently
treats them similarly. That is too weak for proof-carrying artifacts, where the
expected trust posture should be stricter than day-to-day development.

Leanix needs explicit policy values that can accept, warn about, or reject
escape hatches depending on context.

## Goal
Introduce development versus strict artifact policy validation for raw shell and
raw graph escape hatches.

## In Scope
- Define a small policy type for at least development and artifact contexts.
- Validate raw shell, raw checks, or raw build steps according to policy.
- Keep development examples ergonomic.
- Make artifact policy stricter than development policy.
- Add an e2e case where strict policy rejects a raw shell check or equivalent
  raw escape hatch.
- Document policy behavior and remaining escape hatches.

## Out of Scope
- Removing raw escape hatches.
- Implementing a warning system unless it falls out naturally.
- Proving shell command semantics.
- Modeling all trust policy classes in the first slice.

## Dependencies
- Builds on `TICKET-0025` typed checks and shell escape reduction.
- Related to `TICKET-0029` lockfile witness metadata.
- Related to artifact manifest policy evidence from `TICKET-0028`.

## Implementation Notes
- Policy should be an explicit value passed to validation or artifact emission,
  not a hidden renderer flag.
- Keep default development behavior compatible with current examples.
- Artifact policy should fail loudly and explain which escape hatch was used.
- Docs should make it clear that strict policy reduces risk but does not prove
  external command behavior.

## Acceptance Criteria
1. `CheckCommand.rawShell` or an equivalent raw escape hatch remains usable in
   development.
2. Strict artifact policy rejects at least one raw shell/check/build-step escape
   hatch.
3. The policy rejection has exact stderr e2e coverage.
4. Artifact generation records or applies the active policy.
5. Docs list policy behavior and remaining allowed escape hatches.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Artifact.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-raw-escape-hatch-policy.md`

## Progress
- Not started.
