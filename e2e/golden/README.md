# Golden Renderer Fixtures

These files pin selected rendered `flake.nix` outputs.

The Rust e2e runner renders each selected case to `generated/flake.nix`,
compares it to the matching fixture here, and only then runs
`nix flake check path:./generated`.

When renderer output changes intentionally:

1. Render the affected case with `nix develop -c lake exe leanix render-... --out generated/flake.nix`.
2. Inspect the generated diff as renderer behavior, not as formatting churn.
3. Update the matching fixture in this directory.
4. Run `nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml`.

