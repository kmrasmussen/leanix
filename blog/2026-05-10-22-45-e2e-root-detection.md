# E2E Root Detection

The Rust e2e harness no longer assumes it was launched from the repository
root.

It now searches upward for `lakefile.lean` and `e2e/runner/Cargo.toml`, accepts
`--repo PATH` for explicit worktree selection, and prints a small `--help`
usage line. That means the harness can be run from subdirectories without
writing `generated/` into the wrong place or invoking `lake` against the wrong
tree.

The verification for this change used the normal root invocation, an
autodetected run from `e2e/golden`, an explicit `--repo` run from `/tmp`, and
the `--help` output.
