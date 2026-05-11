# TICKET-0031: Parsed Nix Summary Contract

## Roadmap Source
This ticket materializes the next nixparserlean interop slice from:

- `roadmap/02-milestones.md` Milestone 5: NixParserLean Contract V2
- `roadmap/03-workstreams.md` Workstream F: NixParserLean Interop
- `roadmap/04-ticket-wave.md` TICKET-0031
- `roadmap/06-open-questions.md` How Should NixParserLean Interop Evolve?

## Problem
Leanix's optional `nixparserlean` interop currently checks generated Nix through
parse/desugar/eval and selected JSON string fragments. That is useful, but it is
fragile and does not read like a stable contract.

The next interop step should check structured facts about generated flakes.

## Goal
Make generated-Nix interop checks less fragile and more meaningful by defining
a parsed summary contract for Leanix-generated flakes.

## In Scope
- Define the desired summary shape for generated flakes.
- Update Leanix e2e expectations to check structured output facts.
- Make sibling `nixparserlean` changes if the required summary mode does not
  exist yet.
- Cover at least inputs, output families, active systems, and default aliases.
- Keep generated interop files under `generated/`.
- Keep docs clear that this is a parse/desugar/top-level contract, not full Nix
  semantic equivalence.

## Out of Scope
- Making Leanix depend on a sibling checkout for normal development.
- Applying `outputs` to real fetched inputs.
- Importing nixparserlean as a Lean library.
- Proving generated Nix is semantically equivalent to Lean values.

## Dependencies
- Builds on `TICKET-0016` Rust-owned nixparserlean interop e2e.
- Builds on `TICKET-0017` parsed Nix round-trip contract.
- May require coordinated work in sibling `../nixparserlean`.

## Implementation Notes
- Start by defining the contract in docs and Rust expectations before making
  broad parser changes.
- If sibling changes are needed, keep them narrow and document the exact
  expected nixparserlean command.
- Keep error output actionable when the sibling checkout is missing, stale, or
  dirty.
- Do not overstate the result: this validates generated syntax and shape only.

## Acceptance Criteria
1. `--nixparserlean-dir` e2e checks structured facts instead of broad JSON
   string fragments.
2. The contract covers input declarations and at least one output alias.
3. Interop docs state the exact checked boundary.
4. Generated files remain ignored/ephemeral under `generated/`.
5. The default Rust e2e path still works without a sibling nixparserlean
   checkout.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`

## Suggested Files
- `e2e/runner/src/main.rs`
- `interop/nixparserlean/README.md`
- `docs/poc.md`
- possibly sibling `../nixparserlean`
- `blog/yyyy-mm-dd-hh-mm-parsed-nix-summary-contract.md`

## Plan
- Extend the Rust interop expectation type so each generated-flake case
  declares parsed facts instead of relying on one-off broad JSON fragments.
- Check input declarations, output families, active systems, default aliases,
  and formatter outputs against nixparserlean `--desugar --format json`.
- Keep the interop files under `generated/interop-nixparserlean/` and preserve
  the default e2e path when no sibling checkout is configured.
- Document the exact parse/desugar/top-level boundary and add a dated blog
  note.

## Progress
- Expanded `ParsedOutputContract` with input declarations, formatter outputs,
  default app aliases, and formatter package targets.
- Added parsed-contract checks for `inputs` and expected input names.
- Added parsed-contract checks for `formatter.${system}` output shape.
- Added parsed-contract checks for default app aliases.
- Added the formatter schema to the optional nixparserlean interop suite.
- Updated interop docs, PoC docs, and added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --nixparserlean-dir ../nixparserlean`
