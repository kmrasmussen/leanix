# Closure Proof Hardening

Package closure evidence now has named graph properties.

Before this slice, `PackageClosure.Valid` exposed two raw facts: the reference
resolution boolean returned `true`, and the finite acyclicity boolean returned
`true`. That was useful proof-carrying data, but the public shape was tied
directly to implementation details.

The checked graph now carries `PackageClosure.ReferencesResolve` and
`PackageClosure.NoFuelBoundedCycles`. The current constructors are still backed
by the same finite checks, so cycle rejection behavior and generated artifacts
stay stable. The difference is that the evidence names now describe the intended
graph invariants, which gives future proof work a clearer target.

`docs/closure-proof-strategy.md` records the strategy and the next step:
replace the checker-backed constructors with lemmas from a proof-friendlier
reachability relation or topological sort. For now, the Rust e2e harness keeps
the existing invalid cycle case in place.
