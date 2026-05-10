# First Typed Closure

Leanix now has its first real graph invariant.

`BuildExpr.package` lets a package build expression depend on another package
in the same system output set. Validation checks two things before rendering:

- every package reference points at an existing package
- package references are acyclic

The Rust e2e runner now covers both sides:

- a valid closure example where `helloWrapper` depends on `helloTool`
- an invalid missing-reference example
- an invalid two-package cycle

This is the first point where Leanix does more than generate Nix. It rejects
malformed build graphs before Nix sees them.

The boundary still feels right: Lean owns the typed graph and invariant checks;
Rust owns running generated flakes and asserting e2e behavior.
