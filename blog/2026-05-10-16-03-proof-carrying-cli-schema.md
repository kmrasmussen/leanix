# Proof-Carrying CLI Schema

`ValidatedSchema` now carries proof data.

For `CliProject`, Leanix defines a proposition:

```lean
CliProject.Valid project
```

It records that the app, development shell, and check use the expected default
names, that the app and check point at the project package, and that the
development shell contains that package.

`CliProject.validateChecked` still returns `Except String`, but success now
constructs a `ValidatedSchema (CliProject system)` with those proof fields.
That means downstream APIs can distinguish raw schema data from checked,
proof-carrying schema data.

This is the first move from "a Lean program checked this" toward "the checked
thing has a stronger type."
