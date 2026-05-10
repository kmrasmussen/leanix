# Proof-Carrying Flake Artifact Ticket

Added `TICKET-0007`, an ambitious next milestone for Leanix.

The idea is to make Leanix emit a directory artifact instead of only a
`flake.nix`: rendered Nix, a machine-readable manifest, the source reference,
checked invariant names, and enough metadata for the Rust harness to replay the
verification.

This fits the split we want:

- Lean owns typed build graph claims and proof/validation boundaries.
- Rust owns filesystem layout, subprocesses, manifest checking, and e2e replay.
- Nix remains the backend that evaluates and builds the rendered artifact.

The first slice is intentionally small: define a manifest for the showcase,
emit an artifact directory, and verify it from Rust.

