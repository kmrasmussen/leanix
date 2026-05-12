# Local CI Parity

The pinned-input CI failure exposed a workflow gap: Leanix had a strong local
gate, but no single command that intentionally mirrored the GitHub Actions
checks before push.

This step adds `scripts/ci-local`, which runs:

- `nix flake check`
- `nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml`

It also adds an opt-in `scripts/install-pre-push-hook` helper. The hook delegates
to `scripts/ci-local`, so local enforcement uses the same command documented for
manual pre-push checks.
