# Leanix Examples

Examples here are user-facing demonstrations of what Leanix can do.

The Lean source of truth still lives in `Leanix/Examples.lean`; this directory
explains how to run notable examples and what each one demonstrates.

Use `leanix list-examples` to print the registry of renderable examples. Use
`leanix render NAME --out generated/flake.nix` for the generic path, or keep
using the older `render-*` commands when you want the stable compatibility
spelling used by existing e2e fixtures.

For schema selection, guarantees, and raw-`Flake` boundaries, see
[`docs/schema-catalog.md`](../docs/schema-catalog.md).

## Current Showcase

- [proof-carrying-cli-closure](proof-carrying-cli-closure/) demonstrates the
  strongest current path: a proof-carrying CLI schema whose package depends on a
  typed package closure and uses structured build steps.

The CLI also exposes `leanix render-multi-system --out generated/flake.nix`,
which demonstrates the renderer's current graph-level multi-system output
shape, and `leanix render-multi-system-schema --out generated/flake.nix`,
which demonstrates the typed authoring path for one CLI project across two
systems.

`leanix render-library-schema --out generated/flake.nix` demonstrates the
package-first `LibraryProject` schema. `leanix render-multi-app-schema --out
generated/flake.nix` demonstrates `MultiAppProject`, where several app outputs
share one package graph. `leanix render-service-schema --out
generated/flake.nix` demonstrates `ServiceProject`, where one daemon-style
package owns the default app and one or more health checks. `leanix
render-formatter-schema --out
generated/flake.nix` demonstrates `FormatterProject`, where a formatter output
is a typed package reference rendered as `formatter.${system}`. Use these
schemas for known conventions; keep using raw `Flake` values when experimenting
with output shapes Leanix has not named yet or when modeling runtime service
management beyond package/app/check relationships.

The closure and showcase examples now author `helloWrapper` through
`helloWrapperPlan`, a `BuildPlan` that lowers to the same generated Nix as the
previous direct `BuildExpr` version.

That same closure path covers two typed builder identities: `helloToolPlan` is a
known nixpkgs package identity, and `helloWrapperPlan` is an executable text
wrapper with named arguments.

`leanix render-build-plan-text-file --out generated/flake.nix` demonstrates
`BuildPlan.installTextFile`. The hashed source fixture now uses
`BuildPlan.copyInputFile`, so its source input reference is visible at the plan
layer before lowering to structured backend steps. `leanix
render-build-plan-run-executable --out generated/flake.nix` demonstrates
`BuildPlan.runPackageExecutableToOutput`, which runs a package executable and
writes stdout to `$out`.

The self-check package now uses `BuildPlan.leanPackageFromInputTree` instead of
direct `BuildExpr.runSteps`, so the `leanixSrc` input reference is visible at
the plan layer before lowering.

The closure check now uses a typed `CheckCommand.packageExecutableToOutput`
instead of raw shell. The source fixture example also uses the structured
`BuildStep.copyFile` step for its final copy.
