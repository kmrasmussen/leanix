# Package Closure Proof Strategy

Leanix currently checks package closure with a finite graph walk:

- every `BuildExpr.package` and typed build-text package reference must resolve
  to a package in the same system graph
- every package dependency edge is searched with `packages.length + 1` fuel to
  reject cycles

`PackageClosure.Valid` now carries named evidence:

- `PackageClosure.ReferencesResolve`
- `PackageClosure.NoFuelBoundedCycles`

Those properties are still produced by the current boolean checker. The point of
this slice is to move the public evidence shape away from raw boolean fields so
future proof work has stable names to strengthen. Existing code can still recover
the checked boolean facts through `CheckedPackageGraph.refsResolve` and
`CheckedPackageGraph.acyclicByFuel`.

The next proof step should replace the `checked` constructors with lemmas from a
clearer graph algorithm, such as a topological sort or an explicit reachability
relation over package names. Until then, the cycle rejection path stays exactly
the same and the Rust e2e harness continues to assert the structured cycle
error.
