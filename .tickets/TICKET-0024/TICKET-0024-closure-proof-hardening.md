# TICKET-0024: Closure Proof Hardening

## Problem
`PackageClosure.Valid` currently records boolean facts about reference
resolution and fuel-bounded acyclicity. That is useful proof-carrying data for
the PoC, but it is still tied to the implementation shape of the finite check.

The next proof step is to connect the check to a clearer graph property, or to
replace it with an algorithm whose proof story is easier to maintain.

## Goal
Harden package-closure evidence so it expresses the intended graph invariant,
not only that the current boolean function returned `true`.

## In Scope
- Define a graph reachability or acyclicity proposition for package graphs.
- Prove that successful validation implies package references resolve.
- Prove soundness and, if practical, completeness of the finite acyclicity
  check.
- Or replace the check with a proof-friendlier topological sort and prove the
  relevant relationship.
- Keep current invalid cycle e2e coverage.

## Out of Scope
- Proving Nix build evaluation behavior.
- Proving renderer correctness.
- Optimizing large package graphs unless the proof work naturally exposes a
  better algorithm.

## Acceptance Criteria
1. `CheckedPackageGraph` carries evidence for a named graph property stronger
   than "this boolean returned true".
2. The cycle rejection path still reports useful structured errors.
3. Existing examples continue to elaborate without fragile proof terms.
4. A design note explains the chosen proof strategy.

## Plan
- Name the closure evidence as graph properties instead of exposing only raw
  boolean equalities on `PackageClosure.Valid`.
- Keep the current finite checker as the proof-producing implementation for
  this slice, so cycle errors and e2e behavior remain stable.
- Preserve compatibility helpers for code that needs to recover the checked
  boolean facts at renderer/artifact boundaries.
- Add a design note explaining why this keeps the proof story incremental.
- Run the existing Lean and Rust e2e gates, including the invalid cycle case.

## Progress
- Replaced raw boolean fields on `PackageClosure.Valid` with named
  `ReferencesResolve` and `NoFuelBoundedCycles` evidence.
- Kept compatibility accessors on `CheckedPackageGraph` for code that needs the
  checked boolean facts.
- Updated the closure proof example to use the named evidence constructors.
- Added `docs/closure-proof-strategy.md` and a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
