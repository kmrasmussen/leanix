# Package Closure Proof Strategy

Leanix currently checks package closure with a finite graph walk:

- every `BuildExpr.package` and typed build-text package reference must resolve
  to a package in the same system graph
- every package dependency edge is searched with `packages.length + 1` fuel to
  reject cycles

The package graph now has an explicit edge relation over package names:

- `PackageClosure.edgeBool packages fromName toName` is the executable edge
  predicate used by the checker.
- `PackageClosure.Edge packages fromName toName` is the named proposition for a
  checked edge between two package names.
- `PackageClosure.EdgeTargetsNamed` records that every dependency target named
  by those edges is also a package in the graph.

`PackageClosure.Valid` now carries named evidence:

- `PackageClosure.EdgeTargetsNamed`
- `PackageClosure.ReferencesResolve`
- `PackageClosure.NoFuelBoundedCycles`
- `PackageClosure.NoTopologicalCycles`

Those properties are still produced by executable boolean checkers.
`ReferencesResolve` is intentionally connected to the edge-target property: a
`ReferencesResolve` witness can be converted to `EdgeTargetsNamed`, and
`CheckedPackageGraph.edgeTargetsNamed` exposes the checked edge-target boolean
fact. `NoTopologicalCycles` is backed by a remove-ready-nodes topological
checker over package names. Existing code can still recover checked facts
through `CheckedPackageGraph.refsResolve`, `CheckedPackageGraph.acyclicByFuel`,
and `CheckedPackageGraph.topologicalAcyclic`.

`CheckedSystemOutputs system` now embeds `CheckedPackageGraph` and adds the
output-family evidence around it:

- `SystemOutputs.AppReferencesResolve`
- `SystemOutputs.DevShellReferencesResolve`
- `SystemOutputs.CheckReferencesResolve`
- `SystemOutputs.FormatterReferenceResolve`

That boundary is intentionally per-system. It gives artifacts and future
renderer refactors a precise checked value to point at without changing the
current generated Nix shape.

What is now proven is still modest: checked graph evidence has named closure
properties over package-name edges, and valid examples carry those properties
without hand-written proof terms beyond `native_decide`.

What remains checker-backed:

- the edge-target property is still backed by `edgeTargetsNamedBool`
- acyclicity is still backed by fuel-bounded reachability
- topological acyclicity is still backed by `topologicalAcyclicBool`
- duplicate package names are still rejected as validation preconditions outside
  this graph property

The next proof step should replace the `checked` constructors with lemmas that
connect topological reduction success to absence of cycles, or with a stronger
reachability relation over package names. Until then, the cycle rejection path
stays exactly the same and the Rust e2e harness continues to assert the
structured cycle error.
