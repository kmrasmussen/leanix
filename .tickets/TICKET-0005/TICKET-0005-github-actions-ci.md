# TICKET-0005: GitHub Actions CI

## Problem
The repository has local checks, but GitHub does not yet run them on push or pull
request.

## Goal
Add CI for Leanix's current contract.

## In Scope
- GitHub Actions workflow using Nix.
- `nix flake check`.
- Rust e2e harness under `nix develop`.
- Clear caching decisions, even if the first version is simple.

## Out of Scope
- Matrix testing all systems.
- Binary cache publishing.

## Acceptance Criteria
1. GitHub Actions runs on push and pull request.
2. CI executes root `nix flake check`.
3. CI executes the Rust e2e harness.

## Progress
- Added `.github/workflows/ci.yml`.
- CI runs on `push` and `pull_request`.
- CI installs Nix, runs `nix flake check`, then runs the Rust e2e harness under
  `nix develop`.
- First caching decision is intentionally simple: use public Nix substituters
  and no project binary cache until Leanix has an explicit cache trust model.
