# TICKET-0010: Total Flake Renderer

## Problem
The renderer is partial in three ways the model does not advertise.

1. **Single-system only.** `Outputs` is `(system : System) -> List _` and
   `System.all` enumerates four systems, but `renderFlake` rejects more than
   one active system:
   ```text
   the PoC renderer currently supports exactly one active system
   ```
   So a model designed for cross-platform output produces an error any time
   it would actually be cross-platform.
2. **Fuel-bounded build expressions.** `renderBuildExprWithFuel` carries a
   hard-coded fuel of `64` to satisfy Lean's termination checker. When fuel
   reaches `0`, the renderer emits the literal Nix string
   `throw "Leanix render depth exceeded"` into the generated flake, which
   would fail at `nix eval` time with no Lean-side signal that anything went
   wrong.
3. **Default package re-renders the build expression.** `renderPackageDefaults`
   adds `default = pkgs.runCommand …` next to the named package, duplicating
   the entire builder body. The result is two distinct Nix derivations with
   the same content (see `examples/proof-carrying-cli-closure/expected.flake.nix`
   lines 14–22 vs 24–31). Default *apps* are rendered as attrset references;
   default packages are not.

## Goal
Make the renderer total over the model's supported domain, with a single
predictable shape for `default` outputs.

## In Scope
- Multi-system rendering: emit `packages.${system}` blocks for every system
  with outputs, and gate `pkgs = import nixpkgs { inherit system; }` so it
  works for multiple systems (e.g. `forAllSystems`-style helper or one block
  per system).
- A renderer for `BuildExpr` that does not depend on a fuel argument. Either
  use Lean structural recursion with a termination proof, or surface
  exhaustion as `Except String String` instead of as a Nix string.
- Render `default` packages as attribute aliases:
  `default = self.packages.${system}.<name>;` matching how default apps are
  rendered today.
- Update the showcase golden flake to reflect the new shape.
- Tests in the Rust e2e harness covering at least one multi-system flake and
  the new default-package rendering.

## Out of Scope
- Per-system divergent output sets (different package names per system are a
  later concern; first cut may assume the same outputs across systems).
- Cross-compilation host/build/target distinctions.
- Parsing the rendered flake back via `nixparserlean`.

## Acceptance Criteria
1. `renderFlake` does not produce a "render depth exceeded" Nix string under
   any input; depth issues are a Lean-level error or do not exist.
2. `renderFlake` emits a coherent flake when at least two systems are active.
3. `default` packages are rendered as `self.packages.${system}.<name>`
   references, not duplicated builder bodies.
4. The Rust e2e harness has a multi-system case and an updated showcase
   golden file that reflects the alias-style default.

## First Slice
1. Replace `default = …builder…` with the alias form. Update
   `expected.flake.nix` and re-run e2e.
2. Promote `renderBuildExprWithFuel`'s `0` case to an `Except` error and
   thread it out through `renderBuildExpr`.
3. Tackle multi-system support last; the wrapper attrset shape (`forAllSystems`
   vs explicit per-system blocks) is a design decision that should be settled
   in this ticket's analysis.

Each of the three sub-changes can ship independently and unblock a piece of
the renderer.

## Progress

- `renderFlake` now emits one output block per active system instead of
  rejecting flakes with more than one active system.
- Added `Examples.multiSystemFlake`, `leanix render-multi-system`, and a Rust
  e2e golden case covering `x86_64-linux` plus `aarch64-linux` packages.
- Changed build-expression rendering to return `Except String String`; depth
  exhaustion is now a Lean render error, not generated Nix code.
- Changed synthetic default packages to alias the first named package with
  `self.packages.${system}.<name>`, matching default app behavior.
- Updated golden renderer fixtures, the proof-carrying showcase expected flake,
  and artifact flake fixtures for the new renderer shape.
