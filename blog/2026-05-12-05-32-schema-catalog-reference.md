# Schema Catalog Reference

The schema surface now has a stable catalog in `docs/schema-catalog.md`.

The document is intentionally code-facing. It lists every implemented schema,
maps each one to its CLI registry name and source example, and states the
validation contract in the same vocabulary as `Leanix/Schema.lean`. It also
keeps the raw `Flake` boundary explicit: raw graph values are still the right
authoring surface for experimental shapes, renderer fixtures, and conventions
Leanix has not named yet.

This is a small documentation step, but it matters because the schema layer is
no longer a single `CliProject` demo. `LibraryProject`, `MultiAppProject`,
`FormatterProject`, `MultiSystemCliProject`, and `ServiceProject` now each need
a durable answer to "which one should I use?"
