# Schema Catalog

Leanix schemas are typed authoring shortcuts for common flake shapes. They sit
above raw `Flake` and `Outputs` values: a schema validates its own convention,
lowers to ordinary output families, and then the normal graph validation checks
package, app, shell, check, formatter, source, and build references.

Use a schema when the project shape matches a named convention and a validation
error should explain that convention. Use raw `Flake` when the output graph is
experimental, intentionally irregular, or outside the current schema vocabulary.

## Catalog

| Schema | Use When | CLI Example | Source Example | Invalid Fixture |
| --- | --- | --- | --- | --- |
| `CliProject system` | One package owns the default app, default dev shell, and default check. | `cli-schema`; `showcase` for the proof-carrying closure path | `helloCliProject`; `showcaseCliProject` | `render-invalid-cli-schema` |
| `MultiSystemCliProject` | One logical CLI project has per-system `CliProject` values for at least two systems. | `multi-system-schema` | `multiSystemCliProject` | `render-invalid-multi-system-schema` |
| `LibraryProject system` | A package is the main output, with a default dev shell and default check but no app. | `library-schema` | `libraryProject` | `render-invalid-library-schema` |
| `MultiAppProject system` | One package graph intentionally exposes several app outputs. | `multi-app-schema` | `multiAppProject` | `render-invalid-multi-app-schema` |
| `FormatterProject system` | A flake exposes `formatter.${system}` as a typed package reference. | `formatter-schema` | `formatterProject` | `render-invalid-formatter-schema` |
| `ServiceProject system` | One daemon-style package owns the default app, default dev shell, and one or more service checks. | `service-schema` | `serviceProject` | `render-invalid-service-schema` |

Every CLI example can also be rendered through the registry:

```sh
lake exe leanix list-examples
lake exe leanix render service-schema --out generated/flake.nix
```

The compatibility commands, such as `render-service-schema`, remain available
because the e2e harness and golden fixtures use stable command names.

## Shared Conventions

All schema output references are still checked again by graph validation after
lowering, but schema validation runs first and reports schema-specific errors.

Current shared conventions:

- default-oriented schemas require conventional outputs to be named `default`.
- package references must resolve inside the same system package graph.
- app, shell, and check references stay system-local because their types are
  indexed by `System`.
- schemas may require a minimum output count, such as at least two apps for
  `MultiAppProject` or at least one check for `ServiceProject`.
- schema examples should have a valid render path, an invalid exact-stderr e2e
  case, and documentation that says when not to use the schema.

## Schema Details

### `CliProject system`

`CliProject` is the strict default CLI shape:

- one project package plus optional extra packages
- one app named `default`
- one dev shell named `default`
- one check named `default`
- the app and check point at the project package
- the dev shell contains the project package

Use it for executable projects where the default app is the main user entry
point. `showcaseCliProject` also demonstrates the proof-carrying path through
`CliProject.validateChecked` and `Flake.fromValidatedSchema`.

Drop to raw `Flake` or use another schema when a package exposes several apps,
has no app, or needs non-default output names as part of its public interface.

### `MultiSystemCliProject`

`MultiSystemCliProject` groups optional per-system `CliProject` values under one
logical project. It requires at least two active systems and delegates each
active system to the normal `CliProject` validator.

Use it when the project is still a CLI-shaped project, but the authoring unit is
the cross-system project rather than one system at a time.

Use raw `Flake` when the systems have materially different output families or
when only some systems are CLI-shaped.

### `LibraryProject system`

`LibraryProject` is package-first:

- one library package plus optional extra packages
- one dev shell named `default`
- one check named `default`
- the check points at the library package
- the dev shell contains the library package

Use it when there is no app output and the package is the primary artifact.

Use raw `Flake` when a library needs several public packages, several checks
with distinct meanings, or a formatter/app convention too.

### `MultiAppProject system`

`MultiAppProject` owns a package graph plus multiple app outputs:

- at least two apps
- app package references must resolve
- dev-shell package references must resolve
- check package references must resolve

Use it when multiple app outputs are first-class and should not be collapsed
into a single `default` command.

Use raw `Flake` when the app graph also needs stronger relationships that the
schema does not express yet, such as app groups, generated app matrices, or
custom defaulting rules.

### `FormatterProject system`

`FormatterProject` models the common `formatter.${system}` output:

- one or more packages
- a formatter package reference that resolves inside that package graph

Use it when the formatter is the only schema-level convention needed.

Use raw `Flake` or a future composition helper when a formatter is only one
piece of a larger schema-shaped project.

### `ServiceProject system`

`ServiceProject` is a daemon-style convention without runtime service policy:

- one service package plus optional supporting packages
- one app named `default`
- one dev shell named `default`
- one or more checks
- the app points at the service package
- every check points at the service package
- dev-shell and check references resolve inside the same package graph
- the dev shell contains the service package

Use it when the important shape is "run this daemon-like command and check it"
through package/app/check wiring.

Use raw `Flake` when the project needs to model process supervision, ports,
sockets, systemd units, deployment targets, or runtime policy. Those are outside
the current Leanix schema model.

## Raw `Flake` Boundary

Raw `Flake` and `Outputs` values are an intentional escape hatch, not a failure
case. They remain the correct authoring surface for:

- output families that do not have a named schema yet
- experimental graph shapes that should not be stabilized into a schema
- projects where app/check/default conventions differ by design
- renderer or validation fixtures that need precise low-level control
- future schema ideas before they have enough real examples

Raw flakes still pass through `Flake.validateChecked` before rendering through
the normal CLI path. They just skip schema-specific convention checks.

## Adding A Schema

A new schema should land only when there is a real repeated shape to name.
Before it is treated as part of the catalog, add:

- a concrete schema type in `Leanix/Schema.lean`
- a valid example in `Leanix/Examples.lean`
- a CLI registry name and compatibility command in `Main.lean`
- a golden fixture when the output is stable enough to compare
- one invalid exact-stderr e2e case
- catalog, example, and PoC documentation
- a dated blog note for the step
