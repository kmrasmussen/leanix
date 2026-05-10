# NixParserLean Interop Starts

Added `interop/nixparserlean/` as a deliberately small local bridge.

Leanix now has a documented way to render its example flakes and then ask the
sibling `nixparserlean` checkout to desugar and evaluate those generated
flakes. This checks a useful contract: Leanix's backend Nix should stay inside
the Lean Nix model's supported dialect.

The bridge is intentionally not a third repository and not a shared Lean
dependency. It is just a smoke lane:

```text
Leanix value -> generated flake.nix -> nixparserlean --desugar / --eval
```

That is the right level for now. The generated flakes already exercise dynamic
attributes, attrset lambdas, applications, selections, indented strings, and
string interpolation. If this becomes load-bearing, the next step is to move
the check into the Rust e2e harness with a configurable nixparserlean path.
