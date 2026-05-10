# TICKET-0013: Showcase Source Canonical Excerpt

## Problem
`examples/proof-carrying-cli-closure/source.lean` redefines
`helloToolPackage`, `helloWrapperPackage`, and `showcaseCliProject` in a
fresh `Leanix.ProofCarryingCliClosure` namespace. The canonical definitions
live in `Leanix/Examples.lean` under `Leanix.Examples`.

The Rust e2e harness only checks that the standalone file elaborates:

```rust
lean_source: Some("examples/proof-carrying-cli-closure/source.lean"),
```

Nothing asserts the two definitions are equal. They can drift — someone can
edit `Examples.lean` for the renderer path and forget the standalone excerpt,
or vice versa. The showcase README presents `source.lean` as "the local
excerpt" of a single source of truth, which is currently wishful.

## Goal
Make the showcase source file an actual, enforced excerpt of the canonical
definitions.

## In Scope
- One of:
  - generate `examples/proof-carrying-cli-closure/source.lean` from
    `Leanix/Examples.lean` (e.g. via a small Rust step in the e2e harness or
    a `lake exe leanix emit-showcase-source` command), or
  - have `source.lean` `import Leanix.Examples` and re-export the showcase
    project, removing the duplicated definitions, or
  - keep both files but add a Lean theorem (or harness assertion) that the
    two `CliProject .x86_64_linux` values are `BEq`-equal after
    elaboration, failing the harness when they diverge.
- Update the showcase README to match the chosen approach.

## Out of Scope
- A general "extract Lean snippet from project source" tool.
- Restructuring `examples/` for additional showcases.

## Acceptance Criteria
1. Editing `helloWrapperPackage` or `showcaseCliProject` in
   `Leanix/Examples.lean` is either reflected automatically in
   `examples/proof-carrying-cli-closure/source.lean`, or causes the Rust
   e2e harness to fail with a clear "showcase source diverged" message.
2. The e2e harness still elaborates the showcase file as part of its run.
3. The showcase README accurately describes how the excerpt relates to the
   canonical source.

## Notes
The `BEq` route is the smallest change but only catches divergence at e2e
time. The "import and re-export" route is the cleanest if the goal is a
runnable, copy-pasteable example. The "generate" route preserves the demo
property of having a self-contained file but requires a generator. Pick in
analysis.

## Progress
- Chose the import-and-re-export route.
- Replaced the duplicated showcase definitions in
  `examples/proof-carrying-cli-closure/source.lean` with aliases to
  `Leanix.Examples`.
- Kept the e2e harness elaboration of the showcase source file, so broken
  exports or stale names still fail the normal run.
- Updated the showcase README to state that the local excerpt is executable but
  not a second source of truth.
