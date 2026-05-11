# Library and Multi-App Schemas

Leanix now has two schema shapes beyond the original single default CLI
project.

`LibraryProject` is package-first. It carries one main package, optional extra
packages, a default dev shell, and a default check. Validation names the schema
when the dev shell or check does not follow the convention, or when either
stops pointing at packages in the schema's graph.

`MultiAppProject` is for repositories that expose more than one runnable app
from the same package graph. It requires at least two app outputs and validates
that app, dev-shell, and check references stay inside the declared packages.

Both schemas lower to ordinary `Outputs` and still pass through
`Flake.fromSchema`, so the raw graph validator remains the final checked
boundary before rendering. The important distinction is authoring: use a schema
when Leanix knows the convention and should report convention-shaped errors;
drop to raw `Flake` values when exploring an output shape that is not named yet.

The Rust e2e harness now covers both schemas with golden generated flakes and
invalid schema cases with exact stderr checks.
