# Leanix Examples

Examples here are user-facing demonstrations of what Leanix can do.

The Lean source of truth still lives in `Leanix/Examples.lean`; this directory
explains how to run notable examples and what each one demonstrates.

## Current Showcase

- [proof-carrying-cli-closure](proof-carrying-cli-closure/) demonstrates the
  strongest current path: a proof-carrying CLI schema whose package depends on a
  typed package closure and uses structured build steps.

The CLI also exposes `leanix render-multi-system --out generated/flake.nix`,
which demonstrates the renderer's current multi-system output shape.
