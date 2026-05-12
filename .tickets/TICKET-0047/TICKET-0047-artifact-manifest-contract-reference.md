# TICKET-0047: Artifact Manifest Contract Reference

## Roadmap Source
This ticket materializes the artifact-evidence contract slice from:

- `roadmap/02-milestones.md` Goal 2: Artifact Evidence Contract V1
- `roadmap/03-workstreams.md` Workstream D: Proof-Carrying Artifacts
- `roadmap/03-workstreams.md` Workstream E: Rust Harness and Tooling
- `roadmap/04-ticket-wave.md` TICKET-0047
- `docs/vision.md` What Leanix Must Own

## Problem
The manifest has become the carrier for artifact evidence, but its fields are
not yet documented as a stable contract. Some checks are generic Rust preflight
checks, some are Lean evidence names, some are Nix backend witnesses, and some
fields may only be informational. That distinction should be explicit.

## Goal
Document and test the artifact manifest as an evidence contract.

## In Scope
- Add a manifest schema/version reference document.
- Classify each manifest field as checked by Rust, backed by Lean evidence,
  witnessed by Nix, or informational.
- Make the Rust verifier reject missing or mismatched required fields.
- Add at least two exact stderr negative cases for malformed manifests.
- Keep the current Lean artifact emitters working.

## Out of Scope
- Cryptographic signatures.
- Artifact publishing or remote attestation.
- Replacing Nix as the backend witness.
- A general JSON schema dependency unless the no-dependency parser becomes too
  fragile.

## Acceptance Criteria
1. Two artifact shapes still verify through the generic Rust path.
2. Manifest schema/version fields are checked by the Rust verifier.
3. At least two malformed manifest cases fail with exact stderr.
4. Docs state what a verifier may trust and what remains informational.
5. `scripts/ci-local` passes.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `scripts/ci-local`

## Suggested Files
- `docs/artifact-manifest.md`
- `Leanix/Artifact.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `roadmap/05-verification-strategy.md`
- `blog/yyyy-mm-dd-hh-mm-artifact-manifest-contract.md`

## Progress
- Completed in this ticket.

## Plan
1. Document the manifest schema and classify each field by trust boundary.
2. Add Rust verifier checks for manifest `formatVersion` and
   `rendererVersion`.
3. Add exact e2e rejection cases for missing and mismatched schema fields.
4. Keep both current artifact emitters passing the generic verifier.

## Result
- Added `docs/artifact-manifest.md`.
- The Rust verifier now rejects missing or unsupported `formatVersion` and
  `rendererVersion` values.
- Added e2e cases for missing `formatVersion` and mismatched `formatVersion`.
- Kept showcase and service artifacts on the same generic Rust preflight path.

## Verification Result
- Passed: `nix develop --command lake build`.
- Passed: `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`.
- Passed: `scripts/ci-local`.
