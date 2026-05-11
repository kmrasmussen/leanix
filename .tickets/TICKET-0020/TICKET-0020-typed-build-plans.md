# TICKET-0020: Typed Build Plans

## Problem
`BuildExpr` currently mixes two concerns:

- the semantic build plan Leanix wants to own
- the concrete Nix backend expression used to realize it

That was pragmatic for the PoC, but it makes it harder to reason about build
graphs before choosing a backend and harder to explain which invariants belong
to Leanix rather than Nix.

## Goal
Introduce a typed build-plan layer that can be validated independently from
the Nix rendering strategy.

## In Scope
- Define a first `BuildPlan` or equivalent representation for common package
  build intentions.
- Lower build plans to the existing `BuildExpr` or directly to the renderer.
- Preserve package/input dependency extraction from the plan.
- Migrate at least one existing example to the new layer.
- Document which parts are backend-neutral and which remain Nix-specific.

## Out of Scope
- Supporting multiple non-Nix backends.
- Modeling every Nix builder.
- Removing `BuildExpr` in the first slice.

## Acceptance Criteria
1. At least one package is authored as a typed build plan instead of a direct
   Nix-shaped `BuildExpr`.
2. Validation can inspect package/input references before Nix rendering.
3. The generated flake for the migrated example remains equivalent under the
   existing golden/e2e checks.
4. The docs clearly name the new boundary.

## Plan
- Add a first `BuildPlan` type for backend-neutral package intent while keeping
  `BuildExpr` as the current Nix realization layer.
- Lower `BuildPlan` values to `BuildExpr` so the renderer can stay unchanged in
  this slice.
- Expose package/input reference extraction on build plans and validate one
  invalid plan before rendering.
- Migrate one golden-covered example to build-plan authoring while preserving
  its generated flake.
- Update docs and add a dated blog note.

## Progress
- Added `BuildPlan` with reference extraction and lowering to the current
  `BuildExpr` backend.
- Migrated `helloWrapperPackage` to `helloWrapperPlan` via
  `Package.fromBuildPlan`, preserving the existing closure/showcase generated
  flake fixtures.
- Added an invalid build-plan e2e case that fails on a missing package reference
  before rendering.
- Updated docs and added a dated blog note for the build-plan boundary.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
