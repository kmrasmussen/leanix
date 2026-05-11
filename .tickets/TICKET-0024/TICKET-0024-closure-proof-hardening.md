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
