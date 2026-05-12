# CLI Check Command and E2E Filters

The full Rust e2e harness remains the local gate, but it was becoming too
coarse for small renderer and schema loops. A developer who only touched one
registered example still had to choose between a manual render plus
`nix flake check` or the whole suite.

This slice keeps subprocess orchestration in Rust and adds two focused paths:

- `--check-example NAME` renders one CLI registry example to
  `generated/flake.nix` and runs `nix flake check path:./generated`.
- repeated `--only NAME` filters run a subset of the standard valid
  render/check e2e cases by registry name.

The default `cargo run --locked --manifest-path e2e/runner/Cargo.toml` path is
unchanged and remains the command used by `scripts/ci-local` before push. The
focused paths are for iteration; they do not replace the full gate.
