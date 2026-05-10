# First PoC

## Goal

Build one tiny end-to-end path:

```text
Lean value -> validation -> generated flake.nix -> nix build/check
```

The project should not start by reimplementing Nix. It should start by proving
that Lean can be a useful typed front end for one small flake-shaped build graph.

## Shape

The first example should define:

- one supported system, probably `x86_64-linux`
- one package, such as `hello`
- one app that points at that package
- one development shell containing that package
- one check that runs a command against the package

The model should validate:

- package, app, shell, and check outputs are attached to supported systems
- an app cannot point at a package for another system
- source-like inputs have hashes when required
- output names are unique inside each output family

## Renderer

After validation, Leanix should render the restricted graph to a generated
`flake.nix`. The renderer can be intentionally tiny and only support the first
example.

The generated file should be treated as an interop artifact, not as the source
of truth. The source of truth is the typed Lean value.

## Success Criteria

- `lake build` succeeds
- `lake exe leanix render-example --out generated/flake.nix` writes a flake
- `nix flake check path:./generated` succeeds
- the example remains small enough to understand in one sitting

The `path:` prefix matters inside the `leanix` Git repo because `generated/` is
an ignored artifact directory, not the source of truth.

For self-checking generated flakes, pass an absolute source URL such as
`path:/home/kasper/projects/leanix`. A relative parent like `path:..` does not
survive Nix's flake copying semantics when the generated flake itself is the
flake root.

The e2e harness belongs in Rust. Lean should render and validate typed graphs;
Rust should run `lake`, call `nix flake check`, manage generated paths, and
eventually handle snapshots, caches, lockfiles, and corpus-style tests.

The first graph invariant is package closure. `BuildExpr.package` creates a
typed edge from one package to another for the same system. Leanix validates
that every edge points at an existing package and that package edges are
acyclic before rendering.

The first schema invariant is `CliProject`: one package, default app, default
dev shell, and default check. The schema validates this typed contract and then
lowers it to ordinary flake `Outputs`, where graph validation and rendering
continue as before.

The schema boundary is explicit: raw schema values pass through
`ValidatedSchema.validate`, and downstream code can require `ValidatedSchema`
instead of accepting unchecked schema data.

For `CliProject`, this is now proof-carrying rather than only a marker:
`CliProject.Valid` records the equalities and membership check that validation
established.
