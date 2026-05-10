# Canonical Showcase Excerpt

The proof-carrying CLI closure example no longer duplicates its own package and
schema definitions.

`examples/proof-carrying-cli-closure/source.lean` now imports `Leanix.Examples`
and re-exports the canonical showcase values. The file still elaborates in the
Rust e2e harness, but editing `Leanix/Examples.lean` is now reflected through
the excerpt automatically instead of relying on two hand-maintained copies.

This keeps the example honest: it remains a runnable Lean entry point for the
showcase while making `Leanix.Examples.showcaseCliProject` the single source of
truth.
