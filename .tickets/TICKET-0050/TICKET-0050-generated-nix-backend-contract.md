# TICKET-0050: Generated Nix Backend Contract

## Roadmap Source
This ticket materializes the backend-contract slice from:

- `roadmap/02-milestones.md` Goal 4: Backend Contract V1
- `roadmap/03-workstreams.md` Workstream C: Backend Rendering
- `roadmap/03-workstreams.md` Workstream F: NixParserLean Interop
- `roadmap/04-ticket-wave.md` TICKET-0050
- `interop/nixparserlean/README.md`

## Problem
Nix is the active backend, but the supported generated-Nix subset is spread
across renderer code, goldens, interop checks, and notes. That makes it too easy
to confuse Leanix graph claims with backend witness claims.

## Goal
Create a maintained backend contract for the Nix that Leanix emits.

## In Scope
- Document supported input forms, output families, defaults, build expression
  forms, source forms, and known unsupported Nix features.
- Connect representative contract points to goldens or parsed interop checks.
- Improve optional nixparserlean failure reporting if the sibling checkout is
  missing, stale, or contract-incompatible.
- State clearly what Nix still witnesses.

## Out of Scope
- Full Nix semantic equivalence.
- Applying flake `outputs` to real fetched inputs through nixparserlean.
- Making nixparserlean a required dependency for normal development.
- Modeling all nixpkgs builders.

## Acceptance Criteria
1. Docs separate Leanix graph claims from Nix backend witness claims.
2. Optional interop covers the artifact flake and at least three registry
   examples.
3. Interop failure output distinguishes missing checkout, stale/broken sibling
   checkout, and contract mismatch where practical.
4. Generated files remain ephemeral under `generated/`.
5. `scripts/ci-local` passes.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`
- `scripts/ci-local`

## Suggested Files
- `docs/generated-nix-contract.md`
- `Leanix/Render.lean`
- `e2e/runner/src/main.rs`
- `interop/nixparserlean/README.md`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-generated-nix-backend-contract.md`

## Progress
- Not started.
