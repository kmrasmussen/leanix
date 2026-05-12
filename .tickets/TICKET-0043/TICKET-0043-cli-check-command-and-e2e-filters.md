# TICKET-0043: CLI Check Command and E2E Filters

## Roadmap Source
This ticket materializes the developer-workflow slice from:

- `roadmap/02-milestones.md` Milestone 6: CLI and Developer Experience
- `roadmap/03-workstreams.md` Workstream E: Rust Harness and Tooling
- `roadmap/04-ticket-wave.md` TICKET-0043
- `roadmap/06-open-questions.md` How Much CLI Should Lean Own?

## Problem
`leanix render NAME --out FILE` improves discovery, but checking still requires
manual `nix flake check` or the full Rust e2e harness. Developers need a
focused workflow without moving subprocess orchestration into Lean.

## Goal
Add a Rust-owned workflow for focused render-and-check usage, plus e2e filters
for faster development loops.

## In Scope
- Decide whether this is a Rust helper binary or an extension of the e2e
  runner.
- Add a command/filter for running one or a subset of cases.
- Support render plus `nix flake check` for a named registry example.
- Keep Lean focused on pure rendering.
- Document the workflow.

## Out of Scope
- Replacing the full e2e gate.
- Moving Nix subprocess orchestration into Lean.
- A full user-facing package manager.

## Acceptance Criteria
1. One named example can be checked without running the whole suite.
2. Full e2e remains the default gate.
3. Focused checks use the existing CLI registry names.
4. Docs explain when to use focused checks.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- Focused command/filter for at least one example.

## Suggested Files
- `e2e/runner/src/main.rs`
- `Main.lean`
- `README.md`
- `docs/poc.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-cli-check-command-e2e-filters.md`

## Progress
- Not started.
