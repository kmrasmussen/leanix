# TICKET-0014: E2E Harness Root Detection

## Problem
`e2e/runner/src/main.rs::repo_root` returns `env::current_dir()` directly:

```rust
fn repo_root() -> Result<PathBuf, String> {
    env::current_dir().map_err(|err| format!("..."))
}
```

Every `lake` and `nix` invocation runs with that as `current_dir`. If the
binary is invoked from anywhere other than the repository root (a common
mistake when running the cargo binary directly, or running from a worktree
subdirectory), the harness silently runs `lake exe leanix render-…` against
the wrong directory and writes `generated/` somewhere unexpected.

`AGENTS.md` documents the expected invocation
(`cargo run --locked --manifest-path e2e/runner/Cargo.toml`) which carries
the right cwd by convention, but nothing in the harness enforces or detects
that.

## Goal
Make the harness either find the repo root itself or fail loudly when it
isn't there.

## In Scope
- A repo-root detection step that walks upward from `current_dir()` looking
  for a marker file (`lakefile.lean`, or `flake.nix` plus
  `e2e/runner/Cargo.toml`).
- A `--repo` flag for explicit override, useful for worktrees and tests.
- An early error if no marker is found, naming the expected marker.
- A documented invocation in the harness's own usage, not just `AGENTS.md`.

## Out of Scope
- Running the harness across multiple repositories.
- Cargo workspace restructuring.

## Acceptance Criteria
1. `cargo run --locked --manifest-path e2e/runner/Cargo.toml` from the repo
   root behaves as today.
2. Running the harness binary from any subdirectory either finds the repo
   root automatically or exits with a clear error pointing at the marker
   file it failed to find.
3. `--repo PATH` overrides detection.

## First Slice
1. Implement upward `lakefile.lean` search; fall back to current directory
   only if a marker is found there.
2. Add a `--repo` flag.
3. Add a usage line to the binary so `--help` works.
