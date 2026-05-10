# Validated Schema Boundary

Schema validation now leaves a type-level marker.

Raw schema values can be checked with `ValidatedSchema.validate`, which returns
a `ValidatedSchema schema`. Lowering through `Flake.fromValidatedSchema`
requires that wrapper, so callers can choose to work only with checked schema
data.

This is still pragmatic. The wrapper does not yet carry a rich proposition about
the schema. But it creates the boundary Leanix needs:

```text
raw schema -> validated schema -> outputs -> graph validation -> render
```

That boundary is the place where future proof-carrying schema values can land.
