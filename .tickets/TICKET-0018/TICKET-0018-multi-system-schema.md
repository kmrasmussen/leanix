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
