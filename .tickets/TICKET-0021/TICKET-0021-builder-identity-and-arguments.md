# TICKET-0021: Builder Identity and Arguments

## Problem
Builder identity and arguments are still mostly string-shaped. Examples such as
`.nixpkgs "hello"`, raw `runCommand`, native build input lists, and package
`args : List String` do not yet give Leanix much structure to validate.

The README names builder identity and arguments as part of the typed-flake
hypothesis, but the model has only a shallow version of that idea.

## Goal
Make builder identity and builder arguments explicit typed data.

## In Scope
- Replace or wrap stringly builder names with a typed builder identity.
- Model common builder arguments as named typed fields.
- Validate duplicate or unsupported argument combinations where appropriate.
- Render the typed builder contract to Nix.
- Add examples and e2e coverage for at least two builder identities.

## Out of Scope
- Complete nixpkgs builder coverage.
- Derivation-level sandbox/security modeling.
- Cross-compilation argument semantics.

## Acceptance Criteria
1. A package can declare its builder identity without relying on an arbitrary
   stringly `BuildExpr.nixpkgs` path.
2. Builder arguments are represented in a way validation can inspect.
3. The renderer preserves builder identity and arguments in generated Nix.
4. Documentation updates the initial hypothesis with what is now actually
   modeled.

## Plan
- Refine `BuildPlan` so builder identity is carried by typed constructors and
  known nixpkgs package identities rather than arbitrary package-attr strings.
- Move executable-wrapper and input-copy arguments into named structures.
- Add validation for a simple inspectable argument invariant.
- Keep lowering to `BuildExpr` so existing renderer goldens prove generated Nix
  stability.
- Add/update e2e coverage, docs, and a dated blog note.

## Progress
- Added typed known nixpkgs package identities and named argument records for
  executable-wrapper and input-copy build plans.
- Migrated the closure example's tool package to a typed known nixpkgs identity
  while keeping the wrapper package on the structured wrapper identity.
- Added build-plan argument validation for duplicate wrapper arguments and an
  exact-stderr e2e case.
- Updated docs and added a dated blog note for the builder identity boundary.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
