# TICKET-0041: Topological Package Closure Checker

## Roadmap Source
This ticket materializes the package-closure proof slice from:

- `roadmap/02-milestones.md` Milestone 4: Package Closure Proof V2
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0041
- `roadmap/06-open-questions.md` What Is the Right Proof Target for Package Closure?

## Problem
Package cycle rejection is still fuel-bounded reachability. It works, but the
proof story remains indirect and tied to the current finite check shape.

## Goal
Prototype a proof-friendlier topological package graph checker.

## In Scope
- Define a topological ordering or remove-ready-nodes algorithm over package
  names.
- Connect success to named acyclicity evidence.
- Preserve missing-reference and cycle error quality.
- Keep the existing cycle e2e exact, or intentionally update it with a better
  message.
- Write or update proof strategy docs.

## Out of Scope
- Optimizing very large graphs.
- Proving Nix build evaluation behavior.
- Rewriting package dependency extraction.

## Acceptance Criteria
1. `CheckedPackageGraph` carries clearer acyclicity evidence.
2. Invalid cycle e2e remains covered.
3. Examples elaborate without fragile proof terms.
4. Docs explain what is proven versus still checker-backed.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `docs/closure-proof-strategy.md`
- `e2e/runner/src/main.rs`
- `blog/yyyy-mm-dd-hh-mm-topological-package-closure-checker.md`

## Progress
- Completed in this ticket.

## Plan
1. Add a topological remove-ready-nodes checker over package names.
2. Carry its success as named `PackageClosure` evidence.
3. Preserve the existing cycle rejection path and exact e2e error.
4. Document the new checker-backed proof target.

## Result
- Added `PackageClosure.topologicalAcyclicBool` and supporting ready-node
  reduction helpers.
- Added `PackageClosure.NoTopologicalCycles` and exposed
  `CheckedPackageGraph.topologicalAcyclic`.
- `CheckedPackageGraph` now carries both existing fuel-bounded acyclicity and
  the new topological acyclicity evidence.
- Artifact manifests now name `PackageClosure.noTopologicalCycles`.
- Updated proof strategy, PoC, and roadmap docs.

## Verification Result
- Passed: `nix develop --command lake build`.
- Passed: `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`.
