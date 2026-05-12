# Topological Package Closure Checker

Package closure now carries a second acyclicity witness:

```lean
PackageClosure.NoTopologicalCycles
```

The checker repeatedly removes package names whose dependencies are already out
of the remaining graph. Success is recorded on `CheckedPackageGraph` next to the
existing fuel-bounded reachability check.

The existing cycle rejection path stays in place, so the exact invalid-cycle e2e
coverage remains stable while the proof target becomes easier to strengthen.
