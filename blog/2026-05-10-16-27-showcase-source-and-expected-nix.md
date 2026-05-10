# Showcase Source and Expected Nix

The showcase example now includes both sides of the comparison:

- `source.lean`
- `expected.flake.nix`

The Rust e2e harness compares the generated showcase flake against the expected
Nix file, checks that the standalone Lean excerpt elaborates, then runs
`nix flake check path:./generated`.

This makes the demo easier to inspect without reading the whole project. It
also starts the golden-test path from `TICKET-0004`.
