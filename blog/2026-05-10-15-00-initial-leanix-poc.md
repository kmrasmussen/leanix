# Initial Leanix PoC

Leanix started with the mission phrase:

```text
Nix flakes as Lean-checked build graphs.
```

The first proof of concept established a small vertical path:

```text
Lean value -> validation -> generated flake.nix -> nix flake check
```

The initial model defined systems, flake inputs, packages, apps, development
shells, checks, and flake outputs. A typed `hello` example renders to an
ordinary Nix flake and passes `nix flake check path:./generated`.

The important decision is that the generated Nix is an artifact. The Lean value
is the source of truth.
