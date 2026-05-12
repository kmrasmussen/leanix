# TICKET-0048: Agent-Legible Graph Summary

## Roadmap Source
This ticket materializes the first agent-legibility slice from:

- `roadmap/02-milestones.md` Goal 3: Agent-Legible Graph Summary V1
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/03-workstreams.md` Workstream E: Rust Harness and Tooling
- `roadmap/04-ticket-wave.md` TICKET-0048
- `docs/vision.md` The Desired World

## Problem
Leanix has checked graph data, but an agent still has to infer much of the
project shape from docs, manifests, or generated Nix. That leaves generated Nix
too close to being the reasoning substrate.

## Goal
Emit a machine-readable summary derived from checked Leanix values.

## In Scope
- Expose systems, inputs, source trust classes, packages, package edges, apps,
  checks, formatters, policies, and raw escape hatches.
- Derive the summary before rendering Nix.
- Add e2e checks for a canonical registry example.
- Document concrete questions an agent can answer from the summary.
- Keep the output explicitly experimental until enough downstream use exists.

## Out of Scope
- A complete query language.
- Parsing generated Nix to recover the summary.
- NixOS host modeling; that belongs to the design spike in `TICKET-0051`.
- Proving all graph properties beyond the currently checked boundaries.

## Acceptance Criteria
1. At least one command or e2e path emits the summary.
2. E2e validates key summary fields.
3. The summary is derived from checked Leanix values, not generated Nix.
4. Docs list at least six agent questions answerable without reading generated
   Nix.
5. `scripts/ci-local` passes.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `scripts/ci-local`

## Suggested Files
- `Leanix/Artifact.lean`
- `Leanix/Validate.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/graph-summary.md`
- `blog/yyyy-mm-dd-hh-mm-agent-legible-graph-summary.md`

## Progress
- Not started.
