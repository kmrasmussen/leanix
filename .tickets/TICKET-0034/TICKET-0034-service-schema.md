# TICKET-0034: Service Schema

## Roadmap Source
This ticket materializes the next schema-catalog slice from:

- `roadmap/02-milestones.md` Milestone 1: Schema Catalog V2
- `roadmap/03-workstreams.md` Workstream A: Typed Authoring Surface
- `roadmap/04-ticket-wave.md` TICKET-0034
- `roadmap/06-open-questions.md` How General Should Schemas Become?

## Problem
Leanix has schemas for CLI projects, multi-system CLI projects, libraries,
multi-app graphs, and formatters. It does not yet model service-like projects
or daemon-style apps, which are common flake outputs.

Without a service schema, users either squeeze daemons into `CliProject` or
drop to raw `Flake` construction too early.

## Goal
Add a small service-oriented schema that exposes one package, one app entry, a
dev shell, and one or more checks around a daemon command.

## In Scope
- Define a concrete `ServiceProject` or equivalent.
- Validate service app/check package references and naming conventions.
- Render one valid service example with a golden fixture.
- Add one invalid schema convention e2e case with exact stderr.
- Document when to use a service schema instead of `CliProject` or raw `Flake`.

## Out of Scope
- Process supervision or service managers.
- Runtime networking, ports, sockets, or systemd modeling.
- A universal schema language.

## Acceptance Criteria
1. The service schema lowers through `ValidatedSchema`.
2. The generated service flake passes `nix flake check`.
3. The valid service example has a golden fixture.
4. Invalid service schema errors name the violated convention.
5. Docs explain the schema boundary and when raw `Flake` remains appropriate.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Schema.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `e2e/golden/service-schema.flake.nix`
- `docs/poc.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-service-schema.md`

## Progress
- Completed in this ticket.

## Plan
- Add `ServiceProject` with a default service app, default dev shell, service
  package checks, and package-reference validation.
- Add valid and invalid examples, CLI commands, a golden fixture, and e2e
  coverage.
- Document when the service schema fits and when raw `Flake` remains the right
  boundary.
- Verify with `lake build` and the Rust e2e harness before marking complete.

## Result
- Added `ServiceProject` with one service package, optional supporting
  packages, a default service app, a default dev shell, and one or more checks.
- The valid service example lowers through `ValidatedSchema` and renders via
  `render-service-schema`.
- Added `e2e/golden/service-schema.flake.nix` and Rust e2e coverage for the
  valid flake, registry entry, and exact invalid stderr.
- Documented the service/raw-`Flake` boundary in README, PoC docs, examples
  docs, roadmap notes, and a dated blog entry.

## Verification Result
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
