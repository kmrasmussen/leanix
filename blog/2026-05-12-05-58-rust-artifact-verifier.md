# Rust Artifact Verifier

The generic artifact preflight now lives in Rust.

The Lean CLI still emits `flake.nix` and `leanix.manifest.json`, and
`leanix verify-artifact` still works as the showcase compatibility verifier.
But the e2e harness now owns the manifest-level checks that are naturally
filesystem and workflow oriented: declared generated files exist, file hashes
match, replay commands are present, input policy is justified, and the artifact
uses strict escape policy.

The same Rust path now rejects tampered artifacts, missing generated files,
floating flake inputs, missing lockfile witness metadata, and downgraded escape
policy. It also accepts the emitted showcase artifact, the checked-in showcase
artifact, and a lockfile-witness mutation.

This keeps Lean focused on typed graph construction and artifact emission while
moving generic artifact verification toward the Rust-owned operator surface.
