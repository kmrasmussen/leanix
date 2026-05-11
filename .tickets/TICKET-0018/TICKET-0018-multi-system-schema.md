# TICKET-0018: Multi-System Schema

## Problem
The renderer can now emit output blocks for more than one system, but the
schema layer still has only `CliProject system`, which describes one system at
a time.

That means multi-system support exists at the lower graph level but not at the
typed authoring layer where Leanix wants users to work.

## Goal
Introduce a typed schema for one logical project emitted across multiple
systems.

## In Scope
- A schema that groups per-system packages, apps, dev shells, and checks under
  one logical project name.
- Validation that each active system satisfies the same high-level contract.
- Lowering from the schema to `Outputs`.
- A multi-system example and golden renderer fixture.
- Rust e2e coverage, including at least one invalid cross-system or missing
  output case.

## Out of Scope
- Cross-compilation host/build/target modeling.
- Requiring every supported system to be present.
- Per-system lockfile resolution.

## Acceptance Criteria
1. A typed multi-system project lowers to a valid `ValidatedFlake`.
2. The generated flake has at least two active systems.
3. Schema validation catches a missing app/check/package relationship for one
   system.
4. The roadmap clearly distinguishes graph-level multi-system rendering from
   schema-level multi-system authoring.

## Plan
- Add a `MultiSystemCliProject` schema that groups optional per-system
  `CliProject` values under one logical project name.
- Require at least two active systems and run the existing `CliProject`
  validation for every active system.
- Lower the schema to ordinary `Outputs`, then render it through the existing
  `ValidatedFlake` boundary.
- Add CLI commands, a golden fixture, valid and invalid Rust e2e cases, docs,
  and a dated blog note.

## Progress
- Added `MultiSystemCliProject`, schema errors, validation, output lowering,
  example flakes, and CLI commands for both valid and invalid schema paths.
- Added `e2e/golden/multi-system-schema.flake.nix` and Rust e2e coverage for
  the valid render plus an invalid aarch64 app/package relationship.
- Updated the roadmap, PoC docs, and examples README to distinguish graph-level
  multi-system rendering from schema-level authoring.
- Verification:
  - `nix develop -c lake build`
  - `nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml`
