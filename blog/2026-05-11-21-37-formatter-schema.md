# Formatter Schema

Leanix now has its first typed scalar flake output convention:
`formatter.${system}`.

Most earlier output families were attrsets: packages, apps, dev shells, and
checks. Formatter output is different. Nix expects a single derivation per
system, so Leanix now models that shape directly with `Formatter system` instead
of pretending it is another named output set.

The new `FormatterProject` schema keeps the convention small:

- it owns a package graph for one system
- its formatter points at one package in that graph
- schema validation rejects missing formatter package references before
  rendering
- the renderer emits `formatter.${system}` beside the package output block

The e2e harness covers both sides: a golden formatter-schema flake that passes
`nix flake check`, and an invalid formatter schema with exact stderr for a
missing formatter package reference.

This is intentionally not a formatter configuration language. It is one more
typed flake convention that makes the schema catalog useful without turning it
into a universal DSL.
