# Package Closure Graph Relation

Package closure evidence now has an explicit graph relation over package names.

The new pieces are small:

- `PackageClosure.edgeBool packages fromName toName`
- `PackageClosure.Edge packages fromName toName`
- `PackageClosure.EdgeTargetsNamed packages`

`ReferencesResolve` remains the public property used by existing code, but it is
now connected to the edge-target property. A `ReferencesResolve` witness can be
converted into `EdgeTargetsNamed`, and `CheckedPackageGraph.edgeTargetsNamed`
exposes the checked boolean fact for the graph edge target relation.

This does not claim a full graph proof yet. The constructors are still backed by
the executable checker, and cycle rejection still uses the existing
fuel-bounded reachability check. The improvement is that future proof work now
has a stable package-edge target to strengthen instead of only raw list walks.

The existing cycle e2e remains unchanged, and the valid examples still elaborate
with compact `native_decide` evidence.
