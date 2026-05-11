# Parsed Nix Round-Trip Contract

The nixparserlean bridge now checks more than parse/desugar/eval success.

Leanix's Rust e2e runner consumes nixparserlean's
`--desugar --format json` output for selected generated flakes and verifies a
small parsed-output contract:

- output families
- systems
- package, app, dev-shell, and check names
- synthetic default package references

The first covered cases are hello, CLI schema, proof-carrying showcase, and the
multi-system renderer example. The multi-system case is now part of the
nixparserlean interop suite.

This is still intentionally narrow. It checks generated flake shape after
nixparserlean parsing and desugaring. It does not prove full Nix semantics, does
not apply flake outputs to real nixpkgs inputs, and does not claim arbitrary
hand-written Nix round-tripping.
