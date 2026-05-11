# TICKET-0016: Rust-Owned NixParserLean Interop E2E

## Problem
Leanix has a local `interop/nixparserlean/run.sh` smoke lane that renders
selected Leanix flakes and asks `nixparserlean` to desugar and evaluate them.
That lane is useful, but it is outside the normal Rust e2e harness and depends
on ad hoc shell invocation.

If the bridge becomes part of Leanix's contract, it should be exercised by the
same operational layer that already owns subprocesses, generated files, and
Nix interop.

## Goal
Move the current nixparserlean smoke check into the Rust e2e runner as an
optional, configurable interop suite.

## In Scope
- Add a `--nixparserlean-dir PATH` flag, or equivalent environment variable,
  to `e2e/runner`.
- Render the same selected Leanix examples currently covered by
  `interop/nixparserlean/run.sh`.
- Run `nix develop --command lake exe nixparserlean --desugar --file FILE` and
  `--eval --file FILE` against each generated flake.
- Keep the check optional when no sibling checkout is configured, with a clear
  skip message rather than a silent pass.
- Document the interop runner usage in `interop/nixparserlean/README.md`.

## Out of Scope
- Making nixparserlean a Lean dependency of Leanix.
- Proving rendered flakes semantically preserve Leanix graphs.
- Applying flake `outputs` to real nixpkgs inputs.

## Acceptance Criteria
1. `cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`
   runs the desugar/eval bridge.
2. The existing shell script either delegates to the Rust harness or is clearly
   documented as a convenience wrapper.
3. The default e2e run remains usable on machines without a nixparserlean
   checkout.
4. The bridge still writes only ignored generated artifacts.
