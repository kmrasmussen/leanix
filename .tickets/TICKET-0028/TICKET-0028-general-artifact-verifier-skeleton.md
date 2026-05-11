# TICKET-0028: General Artifact Verifier Skeleton

## Roadmap Source
This ticket materializes the verifier-generalization slice from:

- `roadmap/02-milestones.md` Milestone 3: Artifact Manifest V2
- `roadmap/03-workstreams.md` Workstream D: Proof-Carrying Artifacts
- `roadmap/04-ticket-wave.md` TICKET-0028

## Problem
`leanix verify-artifact DIR` exists, but the verifier still knows too much
about the current showcase artifact contract.

That is acceptable for the first proof-carrying artifact, but it will not scale
to multiple generated artifact directories or richer manifest claims.

## Goal
Create a general artifact verification layer that can inspect manifest fields,
generated files, file hashes, and replay commands without hard-coding the
showcase artifact.

## In Scope
- Decide whether generic manifest reading should live in Rust, Lean, or a
  transitional split.
- Verify that every generated file declared by the manifest exists.
- Record and verify hashes for generated files.
- Add a tampered artifact e2e fixture.
- Add a missing generated file negative case.
- Keep the showcase verifier behavior intact during migration.

## Out of Scope
- Public stable artifact format guarantees.
- Cryptographic signatures.
- Remote cache verification.
- Full Nix semantic verification.

## Dependencies
- Builds on `TICKET-0007` proof-carrying artifact work.
- Builds on `TICKET-0022` artifact verifier CLI.
- Should inform but not block `TICKET-0029` lockfile witness metadata.

## Implementation Notes
- Rust is likely the better owner once verification needs directory crawling
  and hashing.
- If verification remains Lean-owned temporarily, keep the boundary documented
  and avoid growing ad hoc JSON string parsing too far.
- Manifest claims should either be checked or clearly documented as
  informational.
- The showcase artifact should continue to pass throughout the migration.

## Acceptance Criteria
1. `verify-artifact` rejects a tampered generated `flake.nix`.
2. `verify-artifact` rejects a missing generated file declared by the manifest.
3. `verify-artifact` still accepts the committed showcase artifact.
4. At least one positive verification path uses generic manifest data instead
   of showcase-specific expectations.
5. Artifact docs describe which manifest fields are checked.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Artifact.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `docs/proof-carrying-artifact.md` or equivalent artifact docs
- `blog/yyyy-mm-dd-hh-mm-general-artifact-verifier.md`

## Progress
- Added manifest `fileHashes` metadata for the generated `flake.nix`.
- Added a Leanix-local content hash used for artifact tamper detection.
- Added manifest-driven `generatedFiles` existence checks to
  `leanix verify-artifact`.
- Added manifest-driven `fileHashes` verification to `leanix verify-artifact`.
- Kept the existing showcase-specific verifier checks after the generic
  manifest preflight.
- Updated the committed proof-carrying showcase artifact manifest.
- Added e2e coverage for tampered `flake.nix` rejection.
- Added e2e coverage for missing generated `flake.nix` rejection.
- Kept generated and committed showcase artifact verification passing.
- Updated artifact docs, README notes, and added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
