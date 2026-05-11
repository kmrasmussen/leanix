# TICKET-0033: CLI Example Registry

## Roadmap Source
This ticket materializes the developer-experience slice from:

- `roadmap/02-milestones.md` Milestone 6: CLI and Developer Experience
- `roadmap/03-workstreams.md` Workstream E: Rust Harness and Tooling
- `roadmap/04-ticket-wave.md` TICKET-0033
- `roadmap/06-open-questions.md` How Much CLI Should Lean Own?

## Problem
The CLI has many specific `render-*` commands. That is useful for e2e coverage,
but it makes the project awkward to explore and does not provide a discoverable
list of examples.

Leanix needs a small example registry that improves the user workflow without
removing the stable commands used by tests.

## Goal
Add a discoverable example registry and one generic render command while keeping
existing commands compatible.

## In Scope
- Add `leanix list-examples`.
- Add `leanix render-example NAME --out FILE`, `leanix render NAME --out FILE`,
  or a similarly simple generic render command.
- Keep old `render-*` commands working.
- Update docs to map examples to commands.
- Update e2e so at least one path uses the registry command.
- Ensure error output for unknown example names is clear.

## Out of Scope
- Removing old commands.
- Adding subprocess-heavy `leanix check` in this ticket.
- Building a package manager or template generator.
- Moving the CLI to Rust unless the implementation proves Lean is the wrong
  owner for this slice.

## Dependencies
- Should preserve all currently golden-covered render commands.
- Related to future Rust-owned subprocess orchestration, but does not require it.

## Implementation Notes
- Keep the registry small and explicit.
- Prefer names that line up with docs and generated fixture names.
- Preserve old command names because the e2e harness and user muscle memory
  depend on them.
- If command parsing gets awkward in Lean, document the point at which a Rust
  wrapper would become useful.

## Acceptance Criteria
1. `leanix list-examples` prints all existing renderable examples.
2. A generic render command can render at least one existing example to a file.
3. The Rust e2e harness covers one registry-based render path.
4. Old render commands still pass their existing e2e checks.
5. Docs explain the registry command and existing compatibility commands.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Main.lean`
- `Leanix/Examples.lean`
- `e2e/runner/src/main.rs`
- `README.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-cli-example-registry.md`

## Progress
- Not started.
