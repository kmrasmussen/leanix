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
