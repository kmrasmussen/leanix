# TICKET-0026: Formatter Schema

## Roadmap Source
This ticket materializes the formatter slice from:

- `roadmap/02-milestones.md` Milestone 1: Schema Catalog V1
- `roadmap/03-workstreams.md` Workstream A: Typed Authoring Surface
- `roadmap/04-ticket-wave.md` TICKET-0026

## Problem
Leanix currently models packages, apps, dev shells, checks, libraries, and
multi-app projects, but it does not expose the common flake convention:

```nix
formatter.${system}
```

Users can still drop to raw `Flake` values, but the typed schema layer should
cover this convention because it is common, system-indexed, and reference-heavy.

## Goal
Add the first typed formatter output model and schema path so a Leanix project
can expose a formatter package through validation before rendering.

## In Scope
- Add a `Formatter` output type or an equivalent formatter field on a schema.
- Render `formatter.${system}` in generated flakes.
- Validate formatter package references before rendering.
- Add one valid formatter example.
- Add one invalid e2e case where the formatter points at a missing package.
- Update schema docs with when to use formatter support.
- Add or update golden fixtures for the generated flake text.

## Out of Scope
- Modeling formatter configuration files.
- Supporting multiple formatters per system.
- Proving formatter behavior.
- Adding a universal schema extension system.

## Dependencies
- Builds on the completed schema work in `TICKET-0018` and `TICKET-0019`.
- Should preserve the existing renderer and e2e behavior from `TICKET-0025`.

## Implementation Notes
- Prefer a small concrete type over a generic attrset escape hatch.
- Keep formatter package references typed as package references where possible.
- Reuse existing schema validation helpers instead of adding another parallel
  resolver.
- If the formatter is added to an existing schema, document the defaulting
  behavior explicitly.

## Acceptance Criteria
1. A generated flake exposes `formatter.${system}` for at least one valid
   example.
2. A formatter reference to a missing package fails validation before rendering.
3. The invalid e2e case has exact stderr coverage.
4. Generated golden output is stable or intentionally updated.
5. `docs/poc.md` or schema reference docs explain formatter support.
6. The dated blog note describes why formatter support belongs in the typed
   schema catalog.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Schema.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `e2e/golden/*.flake.nix`
- `docs/poc.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-formatter-schema.md`

## Progress
- Not started.
