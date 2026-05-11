# TICKET-0023: Lockfile and Pin Policy

## Problem
Leanix can represent flake inputs, source pins, revisions, and hashes, but it
does not yet define how those relate to `flake.lock`.

Artifacts call flake inputs "lockfile-backed", while the model does not record
which lockfile resolved them or whether floating refs are allowed for a given
artifact.

## Goal
Define the first Leanix policy for flake input pinning and lockfile witnesses.

## In Scope
- Decide which input forms are allowed in ordinary development flakes versus
  proof-carrying artifacts.
- Record lockfile path or resolved node metadata in artifact manifests where
  appropriate.
- Validate when an artifact claims reproducible inputs but lacks pin or
  lockfile evidence.
- Add e2e cases for pinned, floating, and rejected input policies.

## Out of Scope
- Implementing a full lockfile manager.
- Resolving remote revisions automatically.
- Replacing Nix's own lockfile behavior.

## Acceptance Criteria
1. The docs describe a clear policy for floating refs, pinned refs, and
   lockfile-backed refs.
2. Artifact manifests record enough information to justify their input trust
   class names.
3. Validation or artifact verification rejects at least one unsupported
   reproducibility claim.
4. Existing development examples remain ergonomic.

## Plan
- Define the first policy: development flakes may use floating refs, while
  proof-carrying artifacts require pinned flake refs or a future lockfile
  witness.
- Stop labeling floating artifact inputs as lockfile-backed unless the manifest
  records evidence.
- Emit pin policy, revision, and hash metadata for pinned artifact inputs.
- Add verifier/e2e coverage that rejects a floating artifact input policy.
- Keep ordinary development render commands ergonomic and unchanged.

## Progress
- Updated artifact input metadata to record trust class, pin policy, revision,
  and hash evidence.
- Switched the proof-carrying showcase artifact to a pinned nixpkgs input while
  leaving ordinary development render paths ergonomic.
- Added verifier rejection for floating artifact flake inputs without a pinned
  ref or lockfile witness.
- Added a Rust e2e policy rejection case that mutates a generated artifact into
  the unsupported floating policy shape.
- Updated docs and added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
