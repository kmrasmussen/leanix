# TICKET-0035: Schema Catalog Reference

## Roadmap Source
This ticket materializes the documentation slice from:

- `roadmap/02-milestones.md` Milestone 1: Schema Catalog V2
- `roadmap/03-workstreams.md` Workstream G: Documentation and Project Narrative
- `roadmap/04-ticket-wave.md` TICKET-0035
- `roadmap/06-open-questions.md` How General Should Schemas Become?

## Problem
Schemas have grown organically, and `docs/poc.md` plus blog notes are no longer
enough as a stable reference. Users need a maintained schema catalog that states
what each schema guarantees and when to use raw graph values instead.

## Goal
Add a schema catalog reference that describes available schemas, contracts,
examples, escape hatches, and selection guidance.

## In Scope
- Add `docs/schema-catalog.md`.
- Include `CliProject`, `MultiSystemCliProject`, `LibraryProject`,
  `MultiAppProject`, `FormatterProject`, and any service schema if it has
  landed.
- Map each schema to examples and CLI registry names.
- Explain shared validation conventions and policy boundaries.
- Add a section for when raw `Flake` remains the correct authoring surface.
- Link the catalog from `README.md`, `docs/poc.md`, and `examples/README.md`.

## Out of Scope
- Creating new schemas.
- Formal schema combinators.
- Replacing `docs/poc.md`.

## Acceptance Criteria
1. The catalog describes every implemented schema.
2. The catalog maps schemas to CLI example names or explains why none exists.
3. README and examples docs link to the catalog.
4. The catalog describes raw `Flake` as an intentional escape hatch.
5. The document reflects current code rather than speculative future shapes.

## Verification
- Documentation review against `Leanix/Schema.lean`, `Leanix/Examples.lean`,
  and `Main.lean`.

## Suggested Files
- `docs/schema-catalog.md`
- `README.md`
- `docs/poc.md`
- `examples/README.md`
- `blog/yyyy-mm-dd-hh-mm-schema-catalog-reference.md`

## Progress
- Completed in this ticket.

## Plan
- Review the implemented schema set against `Leanix/Schema.lean`,
  `Leanix/Examples.lean`, and `Main.lean`.
- Add `docs/schema-catalog.md` with schema selection guidance, guarantees,
  examples, CLI names, invalid fixtures, and raw-`Flake` boundaries.
- Link the catalog from README, PoC docs, and examples docs.
- Add a dated blog note and update roadmap/ticket state.

## Result
- Added `docs/schema-catalog.md`.
- Covered `CliProject`, `MultiSystemCliProject`, `LibraryProject`,
  `MultiAppProject`, `FormatterProject`, and `ServiceProject`.
- Mapped schemas to CLI registry names, source examples, and invalid e2e
  fixture commands.
- Documented shared validation conventions and raw `Flake` as an intentional
  escape hatch.
- Linked the catalog from `README.md`, `docs/poc.md`, and
  `examples/README.md`.

## Verification Result
- Documentation reviewed against `Leanix/Schema.lean`, `Leanix/Examples.lean`,
  and `Main.lean`.
