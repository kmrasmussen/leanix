# TICKET-0019: Library and Multi-App Schemas

## Problem
`CliProject` is a useful first typed schema, but it makes Leanix look narrower
than flakes are in practice. Real projects often expose libraries, multiple
apps, formatters, and several checks under one package graph.

Without additional schemas, users either squeeze projects into `CliProject` or
drop to raw `Flake` construction too early.

## Goal
Add typed schema coverage beyond the single default CLI app case.

## In Scope
- A library-oriented schema with package/check/dev-shell conventions.
- A multi-app schema where several app outputs refer to packages in the same
  graph.
- Formatter output modeling if it falls naturally out of the schema work.
- Schema validation errors that name the violated convention.
- Examples, goldens, and e2e coverage for valid and invalid cases.

## Out of Scope
- A universal schema language.
- Replacing raw `Flake` as an escape hatch.
- Modeling language-specific ecosystems in depth.

## Acceptance Criteria
1. At least two new schemas exist beyond `CliProject`.
2. Each schema has a valid example and one invalid e2e case.
3. Shared schema machinery avoids duplicating the same validation pattern for
   every schema.
4. Documentation explains when to use schemas and when to drop to raw graph
   values.

## Plan
- Add shared schema validation helpers for conventional default names,
  package-reference checks, and minimum output counts.
- Introduce `LibraryProject` for package/check/dev-shell library conventions.
- Introduce `MultiAppProject` for multiple app outputs over one package graph.
- Add valid CLI render targets, golden fixtures, invalid CLI targets, Rust e2e
  assertions, docs, and a dated blog note.

## Progress
- Added `LibraryProject` and `MultiAppProject` in `Leanix/Schema.lean`, both
  lowering to ordinary `Outputs` through the existing schema boundary.
- Added valid and invalid examples in `Leanix/Examples.lean` and CLI commands
  in `Main.lean`.
- Added golden fixtures and Rust e2e coverage for both valid schemas and both
  invalid schema errors.
- Updated docs to describe schema selection and the raw graph escape hatch.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
