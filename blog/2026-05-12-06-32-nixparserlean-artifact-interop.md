# NixParserLean Artifact Interop

The optional nixparserlean bridge now covers the proof-carrying artifact flake.

The Rust harness emits:

```text
generated/interop-nixparserlean/showcase-artifact/flake.nix
```

Then it asks nixparserlean to desugar that flake to JSON and evaluate the
top-level flake record. The parsed contract checks the artifact's output shape,
default package alias, and visible pinned `nixpkgs` fields.

This stays deliberately narrow: parse, desugar, and top-level eval. It does not
apply the artifact outputs to fetched inputs or claim semantic equivalence with
Nix.
