# Artifact Verifier CLI

Leanix now has a first user-facing artifact replay command:

```sh
lake exe leanix verify-artifact DIR
```

The verifier is deliberately scoped to the current proof-carrying showcase
artifact. It reads `leanix.manifest.json` and `flake.nix`, checks the expected
generated files, systems, packages, app/check references, invariant names, and
default package alias, then replays source elaboration and `nix flake check`.

The Rust e2e harness now calls this command for both the generated showcase
artifact and the committed expected artifact. That moves artifact verification
out of private Rust helper code and into the same CLI surface a user can run.

This is still not a stable public artifact verifier, and it is not a proof of
Nix evaluation. It is a concrete replay boundary for the current artifact
format.
