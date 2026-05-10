# Proof-Backed Package Closure

Ticket 0003 moves package closure from a hidden validation fact into an explicit
checked graph value.

`CheckedPackageGraph system` now carries packages together with
`PackageClosure.Valid` evidence. The two facts are deliberately small:

- every package reference in the package build graph resolves inside the same
  package list
- the package graph passes the finite `packages.length + 1` acyclicity check
  Leanix already uses before rendering

That second point matters. This is not pretending to prove Nix evaluation. It
names the exact finite graph check the prototype trusts today and carries that
fact across the boundary.

The showcase excerpt now includes a checked package graph witness, so the Rust
e2e harness elaborates the proof-carrying surface as part of the normal
end-to-end path.
