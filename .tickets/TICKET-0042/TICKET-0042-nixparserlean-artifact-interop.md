# TICKET-0042: NixParserLean Artifact Interop

## Roadmap Source
This ticket materializes the interop expansion slice from:

- `roadmap/02-milestones.md` Milestone 5: NixParserLean Contract V2
- `roadmap/03-workstreams.md` Workstream F: NixParserLean Interop
- `roadmap/04-ticket-wave.md` TICKET-0042
- `roadmap/06-open-questions.md` How Should NixParserLean Interop Evolve?

## Problem
The optional nixparserlean interop suite checks selected generated examples, but
not the proof-carrying artifact flake itself.

## Goal
Add an artifact-flake interop case and tighten the parsed contract around
artifact output shape.

## In Scope
- Render an artifact under `generated/`.
- Run nixparserlean `--desugar --format json` and `--eval` against the artifact
  `flake.nix`.
- Check input declarations, output families, default aliases, and pinned-input
  shape where visible to the parser.
- Document that this is still parse/desugar/top-level eval, not full semantic
  equivalence.

## Out of Scope
- Applying artifact `outputs` to fetched inputs through nixparserlean.
- Making nixparserlean a required dependency for normal development.
- Importing nixparserlean as a Lean library.

## Acceptance Criteria
1. `--nixparserlean-dir` e2e covers the artifact flake.
2. The parsed contract covers input declarations and at least one artifact
   output alias.
3. Interop docs describe the artifact case and its boundary.
4. Generated interop files remain ignored under `generated/`.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`

## Suggested Files
- `e2e/runner/src/main.rs`
- `interop/nixparserlean/README.md`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-nixparserlean-artifact-interop.md`

## Progress
- Completed in this ticket.

## Plan
1. Emit the proof-carrying showcase artifact inside the optional interop output
   directory.
2. Parse and top-level eval the artifact `flake.nix` through nixparserlean.
3. Assert the artifact output contract and visible pinned input fields.
4. Document the artifact interop boundary and non-goals.

## Result
- Added an artifact interop case under `generated/interop-nixparserlean/`.
- The Rust harness now runs nixparserlean `--desugar --format json` and
  `--eval` on the emitted artifact flake.
- The parsed contract checks `nixpkgs`, output families, default package alias,
  and pinned input fields `type`, `owner`, `repo`, `rev`, and `narHash`.
- Updated interop, PoC, roadmap, and current-state docs.

## Verification Result
- Passed: `nix develop --command lake build`.
- Passed: `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`.
- Passed: `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`.
