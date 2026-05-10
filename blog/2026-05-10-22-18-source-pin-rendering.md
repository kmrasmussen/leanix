# Source Pin Rendering

Leanix now keeps source pin metadata at the renderer boundary instead of
quietly dropping it.

Pinned `github:` flake inputs lower to explicit input attrsets carrying
`type`, `owner`, `repo`, `ref`, `rev`, and `narHash`. Unpinned inputs keep the
compact `.url` shape. Hashed `Input.source` values also have a positive e2e
path now: the Rust harness passes an absolute local source fixture, the
renderer lowers it to `builtins.fetchTree`, and `nix flake check` builds the
package that copies from that source.

This keeps the source-trust model honest: a value that looks pinned in Lean is
visible as pinned in generated Nix, and a fixed-output source has a replayable
smoke test rather than only a missing-hash failure case.
