# TICKET-0029: Lockfile Witness Metadata

## Roadmap Source
This ticket materializes the lockfile-evidence slice from:

- `roadmap/02-milestones.md` Milestone 3: Artifact Manifest V2
- `roadmap/03-workstreams.md` Workstream D: Proof-Carrying Artifacts
- `roadmap/04-ticket-wave.md` TICKET-0029
- `roadmap/06-open-questions.md` How Strict Should Artifact Policy Be?

## Problem
Artifact manifests can record pinned refs, and artifact policy can reject
unsupported floating inputs. But Leanix does not yet have a way to represent
lockfile-backed evidence for inputs that are not directly pinned in the Lean
source.

Without that distinction, artifact policy cannot clearly separate directly
pinned inputs from lockfile-witnessed inputs.

## Goal
Define and verify the first lockfile witness metadata for artifact inputs.

## In Scope
- Add lockfile witness fields to `ArtifactInput` or an equivalent manifest
  representation.
- Decide the minimal lockfile node metadata worth recording.
- Verify witness presence for lockfile-backed refs.
- Add an e2e case for a lockfile-backed input.
- Preserve rejection of unsupported floating refs.
- Document development policy versus artifact policy.

## Out of Scope
- Implementing `nix flake lock`.
- Fully parsing every lockfile shape.
- Trusting network resolution during artifact verification.
- Treating lockfile evidence as a proof of upstream source integrity.

## Dependencies
- Builds on `TICKET-0023` lockfile and pin policy.
- Related to `TICKET-0028` general artifact verifier skeleton.
- Related to future strict policy work in `TICKET-0032`.

## Implementation Notes
- Keep pinned refs and lockfile-backed refs as distinct trust classes.
- The verifier should reject a claim that says lockfile-backed without evidence.
- The docs should explicitly state that Leanix records and checks evidence; it
  does not resolve floating refs itself.
- Prefer a small witness structure that can evolve with schema versioning.

## Acceptance Criteria
1. Artifact manifests distinguish directly pinned inputs from lockfile-backed
   inputs.
2. Floating refs without pin or lockfile witness still fail artifact
   verification.
3. A lockfile-backed input fixture verifies successfully.
4. Missing or malformed witness metadata fails with a clear verifier error.
5. Docs state what Leanix checks and what it delegates to Nix or existing
   lockfile data.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Artifact.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- artifact policy docs
- `blog/yyyy-mm-dd-hh-mm-lockfile-witness-metadata.md`

## Progress
- Added lockfile witness fields to `ArtifactInput`: `lockfile`,
  `lockfileNode`, `lockedRev`, and `lockedNarHash`.
- Added artifact verifier policy handling for
  `lockfile-backed-flake-input`.
- Preserved rejection for unsupported `floating-flake-input`.
- Added e2e coverage where a lockfile-backed artifact manifest verifies with
  witness metadata.
- Added e2e coverage where a lockfile-backed artifact manifest fails without
  witness metadata.
- Updated PoC docs, README artifact policy notes, showcase artifact docs, and
  added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
