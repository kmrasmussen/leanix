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
