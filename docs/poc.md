# First PoC

## Goal

The original PoC target was one tiny end-to-end path:

```text
Lean value -> validation -> generated flake.nix -> nix build/check
```

That path now exists. This document describes the shape of the PoC as built,
what each piece does, and which invariants are checked.

## Shape

The smallest example, `helloFlake` (`Leanix/Examples.lean`), defines:

- one supported system, `x86_64-linux`
- one package, `hello`, built from `pkgs.hello`
- one app named `hello` pointing at the `hello` package
- one development shell named `default` containing the `hello` package
- one check named `hello` that runs `hello --version` against the package

Two more elaborate examples build on the same model:

- `closureFlake` adds a typed package closure: `helloWrapper` references
  `helloTool` through `helloWrapperPlan`, a `BuildPlan` value that lowers to
  the structured `runSteps` backend.
- `showcaseCliProject` packages the closure example as a `CliProject` schema,
  takes it through `CliProject.validateChecked` to get a proof-carrying
  `ValidatedSchema`, and then lowers to a `ValidatedFlake`. This is the current
  showcase under `examples/proof-carrying-cli-closure/`.
- `libraryProject` uses `LibraryProject` for package-first projects that still
  want default dev-shell and check conventions.
- `multiAppProject` uses `MultiAppProject` for a single package graph that
  exposes multiple app outputs.
- `formatterProject` uses `FormatterProject` for flakes that expose the common
  `formatter.${system}` convention as a typed package reference.

Use a schema when the project matches a known convention and Leanix should name
that convention in validation errors. Use raw `Flake` and `Outputs` values when
the shape is still experimental or deliberately outside the schema vocabulary.

There is also a `selfFlakeWithSource` example: the CLI renders a flake that
imports the Leanix repository as a `localDevSource` input, copies it with a
structured build step, and runs a structured Lean-project build inside
`nix flake check`. The Rust e2e harness uses this to self-check.

## Validation

`Leanix/Validate.lean` and `Leanix/Schema.lean` together check:

- input names are unique
- `Input.source` pins must carry a `narHash`
- per-system: package, app, dev-shell, and check names are each unique within
  their family
- every `BuildExpr.inputPath` references a declared flake input
- every `BuildExpr.package`, app `packageName`, dev-shell entry, and check
  `packageName` references an existing package for that system
- every validated `BuildPlan` package/input reference can be inspected before
  the plan is lowered to a backend `BuildExpr`
- typed `CheckCommand` package/input references resolve before checks render
- package references are acyclic (fuel-bounded reachability)
- for `CliProject`: app/dev-shell/check are named `default`; app and check
  point at the project package; the dev shell contains the project package.
  These are recorded as proof fields on `ValidatedSchema (CliProject system)`.
- for `LibraryProject`: dev shell and check are named `default`, and both point
  at the library package.
- for `MultiAppProject`: at least two app outputs exist, and app, dev-shell,
  and check references resolve inside the same package graph.
- for `FormatterProject`: the formatter output points at a package in the same
  system package graph.

Graph validation reports `ValidateError` values, and schema validation reports
`SchemaError` values. The CLI renders those values to plain text for humans,
while the Rust e2e harness asserts exact error output for representative graph
and schema failures.

Package closure also has a checked boundary. `CheckedPackageGraph system`
carries a package list plus named `PackageClosure.Valid` evidence:

- `PackageClosure.ReferencesResolve`: package references in build expressions
  resolve to packages in the same graph
- `PackageClosure.NoFuelBoundedCycles`: package dependency cycles are absent
  according to the same finite
  `packages.length + 1` reachability check used by validation

This is not a proof of Nix evaluation behavior. It is proof data for the Leanix
graph assumptions the renderer relies on before emitting package entries. The
current named properties are still produced by the finite checker; the proof
strategy and next strengthening step are documented in
`docs/closure-proof-strategy.md`.

## Renderer

`Leanix/Render.lean` lowers a `ValidatedFlake` to a generated `flake.nix`.
The renderer no longer re-runs graph validation internally; raw `Flake` values
must pass through `Flake.validateChecked` first. It renders inputs, package
builders, apps, dev shells, checks, and `formatter.${system}` outputs, plus a
synthetic `default` package and `default` app when none is declared.

The renderer emits one output block per active system. Each block binds its own
`system` and `pkgs`, so package references such as
`self.packages.${system}."hello"` stay system-local. Synthetic default packages
are aliases to the first named package, matching the default-app shape instead
of duplicating the package builder.

Lockfile-backed `Input.flake` and local source inputs render as flake inputs.
Fixed-output `Input.source` values render as `builtins.fetchTree` bindings and
are excluded from the flake output argument set.

Input policy is split by context. Development flakes may use floating flake
refs, and Nix can create or update `flake.lock` during normal local checks.
Proof-carrying artifacts are stricter: a flake input must either carry a pinned
revision plus hash in the manifest or record concrete lockfile witness metadata.
Floating artifact inputs without either form of evidence are rejected by
`verify-artifact`.

Lockfile-backed inputs are a separate trust class from directly pinned inputs.
The current witness records a lockfile path, lockfile node name, locked revision,
and locked hash. Leanix verifies that those witness fields are present when the
manifest claims `lockfile-backed-flake-input`; it does not run `nix flake lock`
or resolve floating refs itself.

The internal build-expression renderer still uses a finite depth guard, but
exhaustion is now a Lean-side `Except` error. It no longer emits a latent
`throw "Leanix render depth exceeded"` expression into generated Nix.

Local source inputs are not reproducibility claims. `Input.localDevSource`
marks the normal development/self-check path; `Input.impureLocalSource` is
reserved for inputs that are explicitly outside the fixed-output trust model.

String-like Nix literals go through `escapeNixString` before rendering.
Attribute names are emitted as quoted Nix attribute names so package, app,
shell, and check names do not need to be identifier-shaped. Raw indented script
bodies escape Nix's `''` terminator and `${` interpolation marker. Structured
`writeFile` no longer uses shell heredocs; it renders through `pkgs.writeText`,
so lines such as `EOF` are just content. `installExecutableScript` also uses
`pkgs.writeText`, but intentionally allows Nix interpolation in its content so
typed package references can still be baked into wrapper scripts.

The generated file is treated as an interop artifact, not the source of truth.
The source of truth is the typed Lean value.

## Proof-Carrying Artifact

`leanix emit-artifact --out DIR` emits the first proof-carrying showcase
artifact. The directory contains:

- `flake.nix`, the Nix backend artifact
- `leanix.manifest.json`, a machine-readable manifest

The manifest records the renderer version, source reference, generated files,
file hashes, systems, inputs, source trust classes, pin policies, pin metadata,
packages, app/check package references, checked invariant names, and replay
commands.

The current artifact is proof-carrying in a deliberately narrow sense. Lean
checks schema invariants, package closure, finite acyclicity, source trust
requirements, and graph validation before emitting the artifact. The checked
flake carries the validation witness to the render boundary.

`leanix verify-artifact DIR` now has a generic manifest-driven preflight before
the remaining showcase checks. It reads `generatedFiles`, verifies that each
declared file exists, reads `fileHashes`, and rejects tampered files with
mismatched content hashes. The current hash is a Leanix-local content hash for
tamper detection, not a cryptographic signature scheme.

After that generic preflight, the verifier still checks the current showcase
contract: expected systems, packages, app/check references, default package
alias, invariant names, input trust class, source elaboration, and
`nix flake check path:.` replay. The Rust e2e harness calls that same verifier
path, including tampered, missing-file, floating-input, accepted lockfile
witness, and missing-witness rejection cases. Nix remains the external witness
for evaluating and building the rendered flake; Leanix does not claim to prove
Nix evaluation.

## Builder Boundary

`BuildPlan` is the first backend-neutral package authoring layer. It names the
build intention Leanix wants to own, such as using a known nixpkgs package,
producing an executable wrapper for another package, or copying an input tree.
Plans expose `inputRefs` and `packageRefs` for validation before they lower to
`BuildExpr`.

Builder identity is now represented by the `BuildPlan` constructor instead of
being inferred only from raw strings. The first typed identities are:

- `BuildPlan.nixpkgsPackage`, backed by `KnownNixpkgsPackage`
- `BuildPlan.executableTextWrapper`, backed by `ExecutableWrapperArgs`
- `BuildPlan.copyInputTree`, backed by `CopyInputTreeArgs`
- `BuildPlan.copyInputFile`, backed by `CopyInputFileArgs`
- `BuildPlan.installTextFile`, backed by `InstallTextFileArgs`

The wrapper, source-copy, and text-file identities carry named argument
structures. Current validation rejects duplicate executable-wrapper arguments
and missing package/input references before lowering to the backend expression.
`BuildPlan.installTextFile` can also carry typed `BuildText`, so package and
input references inside planned file content are visible to validation.

`BuildExpr` remains the current Nix backend representation. Rendering still
works from `BuildExpr`, and `Package.fromBuildPlan` is the migration bridge from
typed plans to today's renderer.

`CheckCommand` is the typed check-command surface. A check may still use
`CheckCommand.rawShell`, but common checks can now say "run this package
executable and write stdout to `$out`" or "assert this input path exists"
without raw interpolation. Typed check command package/input references are
validated alongside the check's primary package reference.

`BuildExpr.runSteps` is the current structured builder surface. It owns common
operations that Leanix wants to reason about semantically:

- copying a source expression into the build directory
- installing a non-executable text file
- copying a file path to another file path
- installing an executable script
- building a Lean project with `lake build`
- simple filesystem operations such as `mkdir`, `writeFile`, and `chmod +x`

Script and file content can use `BuildText` fragments when it needs typed
references. `BuildText.package` is validated by the same package-reference walk
as `BuildExpr.package`, so package dependencies inside generated scripts are no
longer hidden in raw Nix interpolation.

Raw text and shell remain as explicit escape hatches in five places:

- `BuildExpr.runCommand`, for derivations that have not moved to structured
  steps yet
- `BuildStep.installExecutableScript`, for raw executable text during migration
- `BuildStep.writeFile`, for raw file text during migration
- `BuildStep.run`, for a single command inside an otherwise structured step
  list
- `CheckCommand.rawShell`, for checks that do not fit the typed command surface

Those escape hatches are part of the prototype boundary, not the desired long
term source of build semantics.

## CLI

`lake exe leanix` exposes the PoC commands (`Main.lean`):

- `leanix` — banner
- `leanix render-example --out FILE` — typed `hello`
- `leanix render-closure --out FILE` — typed package closure
- `leanix render-build-plan-text-file --out FILE` — `BuildPlan.installTextFile`
  lowered to a generated package
- `leanix render-cli-schema --out FILE` — `CliProject` lowered to a flake
- `leanix render-formatter-schema --out FILE` — `FormatterProject` lowered to
  `formatter.${system}`
- `leanix render-library-schema --out FILE` — `LibraryProject` lowered to a
  package-first schema flake
- `leanix render-multi-app-schema --out FILE` — `MultiAppProject` lowered to a
  multi-app schema flake
- `leanix render-showcase --out FILE` — proof-carrying CLI closure showcase
- `leanix render-multi-system --out FILE` — graph-level two-system flake
- `leanix render-multi-system-schema --out FILE` — schema-authored two-system
  CLI project
- `leanix render-self --source URL --out FILE` — the self-check flake
- `leanix emit-artifact --out DIR` — proof-carrying showcase artifact
- `leanix emit-showcase-artifact --out DIR` — explicit showcase artifact alias
- `leanix verify-artifact DIR` — replay the current showcase artifact contract
- `leanix render-invalid-cli-schema --out FILE`
- `leanix render-invalid-formatter-schema --out FILE`
- `leanix render-invalid-library-schema --out FILE`
- `leanix render-invalid-multi-app-schema --out FILE`
- `leanix render-invalid-multi-system-schema --out FILE`
- `leanix render-invalid-build-plan-input-ref --out FILE`
- `leanix render-invalid-missing-ref --out FILE`
- `leanix render-invalid-cycle --out FILE`
- `leanix render-invalid-source-missing-hash --out FILE`

The `render-invalid-*` targets are negative tests: the Rust harness
asserts they exit non-zero.

## Rust E2E Harness

`e2e/runner/src/main.rs` (no external crates) drives the full PoC loop:

1. For each valid case: invoke `lake exe leanix render-... --out
   generated/flake.nix`; for selected renderer cases, compare against
   `e2e/golden/*.flake.nix`; then run `nix flake check path:./generated`.
   The showcase also golden-compares against
   `examples/proof-carrying-cli-closure/expected.flake.nix`. The
   `render-multi-system` case pins the graph-level output shape with both
   `x86_64-linux` and `aarch64-linux` package outputs. The
   `render-multi-system-schema` case pins the schema-level authoring path,
   where one logical CLI project lowers into those per-system outputs.
   `render-library-schema` and `render-multi-app-schema` pin the newer schema
   vocabulary beyond the CLI default case. `render-formatter-schema` pins the
   first scalar output convention, where a typed package reference lowers to
   `formatter.${system}`. `render-build-plan-text-file` pins the
   `BuildPlan.installTextFile` lowering path.
2. For each invalid case: invoke `lake exe leanix`, assert non-zero exit, and
   compare exact stderr for the expected error class.
3. For the showcase only: also `lake env lean` the standalone Lean excerpt at
   `examples/proof-carrying-cli-closure/source.lean` to confirm it still
   elaborates against the public Leanix surface.

Run it from the repo root:

```sh
cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

## Success Criteria — status

- ✅ `lake build` succeeds.
- ✅ `lake exe leanix render-example --out generated/flake.nix` writes a flake.
- ✅ `nix flake check path:./generated` succeeds for every valid case.
- ✅ The PoC examples still fit in one sitting.

## Notes for Self-Check Flakes

The `path:` prefix matters inside the `leanix` Git repo because `generated/`
is an ignored artifact directory.

For self-checking generated flakes, pass an absolute source URL such as
`path:/home/kasper/projects/leanix`. A relative parent like `path:..` does not
survive Nix's flake copying semantics when the generated flake itself is the
flake root.

## Boundary

Lean owns the typed graph, validation, schema lowering, and rendering. Rust
owns running `lake`/`nix`, managing the `generated/` directory, and asserting
golden output. Nix is the backend that evaluates and builds the rendered
artifact.

Renderer fixture update workflow is documented in `e2e/golden/README.md`.

Open issues with the current PoC are documented in `flagged.md` at the repo
root.
