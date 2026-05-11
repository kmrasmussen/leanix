# Rust-Owned NixParserLean Interop

The nixparserlean bridge is no longer just a standalone shell smoke test.

The Rust e2e runner now accepts `--nixparserlean-dir PATH` or
`NIXPARSERLEAN_DIR` and, when configured, renders selected Leanix examples into
`generated/interop-nixparserlean/` before running nixparserlean `--desugar` and
`--eval` on each generated flake.

The normal e2e run remains usable without a sibling nixparserlean checkout: it
prints an explicit skip message for the optional bridge. The existing
`interop/nixparserlean/run.sh` script now delegates to the Rust harness with
`--only-nixparserlean-interop`, keeping the old entry point while putting
subprocess orchestration back where this project wants it.

This still proves only the narrow interop claim:

```text
Leanix value -> generated flake.nix -> nixparserlean --desugar / --eval
```

It does not yet compare a parsed AST summary back to the Leanix typed graph.
That is the natural next ticket.
