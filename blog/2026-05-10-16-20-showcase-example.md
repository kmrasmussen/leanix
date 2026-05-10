# Showcase Example

Leanix now has a top-level `examples/` directory.

The first showcase is `examples/proof-carrying-cli-closure`, which combines the
best current pieces:

- proof-carrying `CliProject` validation
- schema lowering to flake outputs
- an extra package dependency in the schema output
- typed package closure validation
- structured builder steps
- generated Nix checked by the Rust e2e harness

The command is:

```sh
lake exe leanix render-showcase --out generated/flake.nix
```

This gives the project a clear demo target for the current milestone.
