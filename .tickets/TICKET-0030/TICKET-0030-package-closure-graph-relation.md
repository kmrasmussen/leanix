# TICKET-0030: Package Closure Graph Relation

## Roadmap Source
This ticket materializes the next closure-proof slice from:

- `roadmap/02-milestones.md` Milestone 4: Package Closure Proof V2
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0030
- `roadmap/06-open-questions.md` What Is the Right Proof Target for Package Closure?

## Problem
`PackageClosure.Valid` has named properties such as reference resolution and
cycle evidence, but those properties are still largely constructed from boolean
checks.

The next proof step should introduce an explicit graph relation over package
names so closure evidence has a clearer target.

## Goal
Define a package graph relation and connect at least one existing checker result
to named closure evidence without making examples brittle.

## In Scope
- Define package-edge relation over package names.
- Define a proof-friendly reachability, topological order, or acyclicity
  proposition.
- Connect reference-resolution checking to the named
  `PackageClosure.ReferencesResolve` property.
- Keep the current cycle e2e behavior exact.
- Update closure proof strategy docs.

## Out of Scope
- Proving full soundness and completeness of every graph checker.
- Removing all runtime validation.
- Proving anything about Nix evaluation.
- Rewriting the package model.

## Dependencies
- Builds on `TICKET-0024` closure proof hardening.
- Should preserve examples and artifacts that mention closure invariant names.

## Implementation Notes
- Keep proof terms in examples small and stable.
- If topological sort is easier than fuel-bounded cycle checks, introduce it
  incrementally and explain the transition.
- Treat duplicate package names as either a separate precondition or a clearly
  named part of the graph property.
- Proof work should produce visible value: stricter validation, clearer
  manifest evidence, simpler examples, or a removed runtime check.

## Acceptance Criteria
1. A package-edge relation exists in Lean and is used by closure evidence or
   strategy docs.
2. At least one checker result is connected to a named package-closure property.
3. Existing valid examples elaborate without fragile proof boilerplate.
4. The invalid cycle e2e case remains exact.
5. `docs/closure-proof-strategy.md` explains what is now proven and what is
   still checker-backed.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `docs/closure-proof-strategy.md`
- `e2e/runner/src/main.rs`
- `blog/yyyy-mm-dd-hh-mm-package-closure-graph-relation.md`

## Progress
- Added `PackageClosure.edgeBool` as the executable package-name edge relation.
- Added `PackageClosure.Edge` as the named proposition for checked package-name
  edges.
- Added `PackageClosure.EdgeTargetsNamed` as closure evidence that edge targets
  are package names in the same graph.
- Connected `ReferencesResolve` to `EdgeTargetsNamed` with
  `ReferencesResolve.toEdgeTargetsNamed`.
- Added `CheckedPackageGraph.edgeTargetsNamed`.
- Updated `PackageClosure.Valid` and the closure example evidence without
  introducing brittle proof terms.
- Updated closure proof strategy docs, PoC docs, and added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
