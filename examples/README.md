# Leanix Examples

Examples here are user-facing demonstrations of what Leanix can do.

The Lean source of truth still lives in `Leanix/Examples.lean`; this directory
explains how to run notable examples and what each one demonstrates.

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
share one package graph. Use these schemas for known conventions; keep using
raw `Flake` values when experimenting with output shapes Leanix has not named
yet.

The closure and showcase examples now author `helloWrapper` through
`helloWrapperPlan`, a `BuildPlan` that lowers to the same generated Nix as the
previous direct `BuildExpr` version.
