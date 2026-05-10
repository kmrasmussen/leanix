# Validated Render Boundary

Leanix now has a load-bearing checked flake boundary.

`Flake.validateChecked` produces `ValidatedFlake`, carrying the raw graph plus
evidence that `validateFlake` succeeded. The renderer consumes that wrapper
instead of taking a raw `Flake` and re-running validation internally. Raw graph
values can still be convenient at the CLI edge, but they must pass through the
smart constructor before they reach `renderFlake`.

Schema lowering now lands on the same boundary. `Flake.fromValidatedSchema`
and `Flake.fromSchema` both produce `ValidatedFlake`, and the validated-schema
path records `FlakeSchema.Valid` in the flake's carried invariant list. The
path is now:

```text
schema -> ValidatedSchema schema -> ValidatedFlake -> rendered flake.nix
```

This also tightened the first schema. `CliProject.validate` and
`CliProject.validateChecked` now share `CliProject.validateEvidence`, so the
six runtime checks and the six proof fields come from one condition list.
