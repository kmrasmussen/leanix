# Total Flake Renderer

The renderer no longer collapses the typed model back to a single active
system.

`renderFlake` now walks every active system and emits a separate output block
for each one. Each block binds `system` and `pkgs`, so package references keep
the same system-local form while the generated flake can contain multiple
systems. The new `render-multi-system` CLI case renders both `x86_64-linux`
and `aarch64-linux`, and the Rust harness golden-compares that output before
running `nix flake check`.

This pass also removed two renderer traps. Synthetic default packages now
alias the first named package instead of re-rendering the builder body, and
build-expression depth exhaustion is a Lean-side `Except` error instead of a
latent `throw` expression in generated Nix.
