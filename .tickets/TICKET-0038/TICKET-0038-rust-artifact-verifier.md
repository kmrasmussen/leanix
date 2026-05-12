# TICKET-0038: Rust Artifact Verifier

## Roadmap Source
This ticket materializes the artifact-verification slice from:

- `roadmap/02-milestones.md` Milestone 3: Artifact Manifest V2
- `roadmap/03-workstreams.md` Workstream D: Proof-Carrying Artifacts
- `roadmap/03-workstreams.md` Workstream E: Rust Harness and Tooling
- `roadmap/04-ticket-wave.md` TICKET-0038
- `roadmap/06-open-questions.md` Where Should Artifact Verification Live?

## Problem
`verify-artifact` still lives in the Lean CLI and uses simple string/line
checks. That is increasingly mismatched with the project boundary that Rust
should own filesystem and manifest verification workflows.

## Goal
Move generic artifact verification into Rust while preserving the existing
Lean-emitted artifact format.

## In Scope
- Add a Rust-owned verifier path in the e2e runner or a small Rust CLI helper.
- Parse enough manifest structure without adding external crates unless needed.
- Verify generated files, file hashes, replay command list, input policy, and
  escape policy from manifest data.
- Keep `leanix verify-artifact` working as a compatibility wrapper or document
  the transition.
- Add e2e coverage for success, tamper, and missing-file failures.

## Out of Scope
- Replacing Lean artifact emission.
- Cryptographic signatures.
- A complete JSON parser unless the no-dependency approach becomes too fragile.

## Acceptance Criteria
1. Rust verifier can verify the showcase artifact.
2. Rust verifier rejects tampered and missing generated files.
3. Input and escape policies are checked from manifest data.
4. Docs state which verifier path is authoritative.
5. Existing artifact e2e cases remain covered.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `e2e/runner/src/main.rs`
- `Main.lean`
- `Leanix/Artifact.lean`
- `docs/poc.md`
- `roadmap/05-verification-strategy.md`
- `blog/yyyy-mm-dd-hh-mm-rust-artifact-verifier.md`

## Progress
- Not started.
