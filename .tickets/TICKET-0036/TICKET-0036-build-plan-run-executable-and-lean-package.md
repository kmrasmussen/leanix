# TICKET-0036: BuildPlan Run Executable and Lean Package Constructors

## Roadmap Source
This ticket materializes the next build-plan slice from:

- `roadmap/02-milestones.md` Milestone 2: BuildPlan V2
- `roadmap/03-workstreams.md` Workstream A: Typed Authoring Surface
- `roadmap/04-ticket-wave.md` TICKET-0036
- `roadmap/06-open-questions.md` How Far Should BuildPlan Move Away From Nix?

## Problem
`BuildPlan` covers several file/source cases, but common package authoring still
falls back to backend-shaped `BuildExpr.runSteps` for running executables and
building Lean packages from input trees.

## Goal
Add build-plan constructors for running a package executable into an output and
building a Lean package from a source/input tree.

## In Scope
- Add named-argument build-plan constructors for executable-run and Lean package
  build cases.
- Lower those plans to the existing backend representation.
- Validate package/input references before lowering.
- Migrate at least one example currently using direct `BuildExpr.runSteps`.
- Add invalid e2e cases for missing package/input references.
- Update docs and examples notes.

## Out of Scope
- Replacing `BuildExpr` as the backend representation.
- Modeling every Lean build option.
- General shell pipelines.

## Acceptance Criteria
1. At least one additional example is authored through `Package.fromBuildPlan`.
2. Package/input references are visible before lowering.
3. Generated golden changes are stable or intentionally documented.
4. Missing package/input references have exact stderr e2e coverage.
5. Docs explain the new constructors and remaining backend boundary.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-build-plan-run-executable-lean-package.md`

## Progress
- Not started.
