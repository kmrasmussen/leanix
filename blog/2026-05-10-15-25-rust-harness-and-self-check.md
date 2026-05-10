# Rust Harness and Self Check

Leanix now has a small typed build expression layer:

- `BuildExpr.nixpkgs`
- `BuildExpr.inputPath`
- `BuildExpr.runCommand`

That is enough to describe a generated self-check flake: Leanix renders a flake
that imports this repository as a local source and builds Leanix with
`lake build`.

The e2e path moved into Rust. The Rust runner asks Leanix to render generated
flakes, then calls `nix flake check path:./generated`. This is the right
boundary: Lean should own typed graphs, validation, and rendering; Rust should
own subprocesses, filesystem paths, generated artifacts, lockfiles, and larger
test harnesses.

One Nix lesson surfaced immediately. A generated flake inside `generated/`
cannot safely refer to its parent with `path:..`, because Nix copies the flake
root to the store before resolving that relative input. The self renderer now
accepts an explicit source URL, and the Rust harness passes an absolute
`path:/.../leanix` URL.
