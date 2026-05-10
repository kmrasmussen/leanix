# First Typed Schema

Leanix now has the first version of typed flake schemas.

The new `FlakeSchema` class describes a type that can validate itself and lower
to ordinary flake `Outputs`. The first schema is `CliProject`, a small contract
for a command-line project:

- one package
- one default app
- one default development shell
- one default check

The schema validates that the app and check point at the project package, and
that the development shell includes it. After that, Leanix lowers the schema to
the same output graph that the renderer already understands.

This is a small step, but it changes the authoring shape: users can start from
a typed project interface instead of directly constructing flake output
families.
