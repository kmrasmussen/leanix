# Parsed Nix Summary Contract

The optional nixparserlean bridge now checks a richer parsed-output contract for
Leanix-generated flakes.

The Rust e2e harness still owns the boundary. For selected cases it renders a
flake into `generated/interop-nixparserlean/`, asks nixparserlean for
`--desugar --format json`, and checks declared facts about the parsed shape.

The contract now includes:

- input declarations
- output families
- active systems
- package/app/dev-shell/check names
- formatter outputs
- default package aliases
- default app aliases

The new formatter-schema case is part of the interop suite, so scalar
`formatter.${system}` output shape is checked by the sibling parser too.

This is still not a full semantic bridge. Leanix does not apply the generated
`outputs` function to real inputs through nixparserlean, and nixparserlean is
not a hard dependency for normal e2e. The default harness still skips interop
unless `--nixparserlean-dir` or `NIXPARSERLEAN_DIR` is provided.
