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
- `serviceProject` uses `ServiceProject` for daemon-style projects with a
  default app, default dev shell, and at least one service health check around
  one main package.
- `formatterProject` uses `FormatterProject` for flakes that expose the common
  `formatter.${system}` convention as a typed package reference.

Use a schema when the project matches a known convention and Leanix should name
that convention in validation errors. Use raw `Flake` and `Outputs` values when
the shape is still experimental, needs process supervision or network/runtime
policy, or is deliberately outside the schema vocabulary.

The maintained reference for schema choice and schema guarantees is
[`docs/schema-catalog.md`](schema-catalog.md).

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
- for `ServiceProject`: the app and dev shell are named `default`; at least one
  check exists; the app, dev shell, and checks resolve inside the same package
  graph; and the app/check outputs point at the service package.
- for `FormatterProject`: the formatter output points at a package in the same
  system package graph.

Graph validation reports `ValidateError` values, and schema validation reports
`SchemaError` values. The CLI renders those values to plain text for humans,
while the Rust e2e harness asserts exact error output for representative graph
and schema failures.

Validation now also produces a per-system checked output boundary.
`CheckedSystemOutputs system` carries the packages, apps, dev shells, checks,
formatter, input names, and the checked package graph for one system. Its named
evidence records that app, dev-shell, check, and formatter references resolve
against the same package graph. `ValidatedFlake` stores those checked outputs
for downstream schema, renderer, and artifact work; the renderer behavior is
unchanged in this slice.

Package closure has its own checked boundary inside that value.
`CheckedPackageGraph system` carries a package list plus named
`PackageClosure.Valid` evidence:

- `PackageClosure.EdgeTargetsNamed`: every package dependency edge points at a
  package name in the same graph
- `PackageClosure.ReferencesResolve`: package references in build expressions
  resolve to packages in the same graph
- `PackageClosure.NoFuelBoundedCycles`: package dependency cycles are absent
  according to the same finite
  `packages.length + 1` reachability check used by validation
- `PackageClosure.NoTopologicalCycles`: the package graph can be reduced by
  repeatedly removing dependency-ready package names

This is not a proof of Nix evaluation behavior. It is proof data for the Leanix
graph assumptions the renderer relies on before emitting package entries. The
current named properties are still produced by executable boolean checks; the
proof strategy and next strengthening step are documented in
`docs/closure-proof-strategy.md`.

## Agent-Legible Summary

`leanix summarize NAME --out generated/graph-summary.json` emits an
experimental graph summary from `ValidatedFlake.checkedOutputs`, before Nix is
rendered. It exposes systems, inputs and source trust classes, package edges,
apps, dev shells, checks, formatters, policy descriptions, raw escape hatches,
and carried invariant names.

The maintained summary contract is documented in
[`docs/graph-summary.md`](graph-summary.md). The summary is the first
agent-facing view intended to answer graph questions without treating generated
Nix as the reasoning substrate.

## Renderer

`Leanix/Render.lean` lowers a `ValidatedFlake` to a generated `flake.nix`.
The renderer no longer re-runs graph validation internally; raw `Flake` values
must pass through `Flake.validateChecked` first. It renders inputs, package
builders, apps, dev shells, checks, and `formatter.${system}` outputs, plus a
synthetic `default` package and `default` app when none is declared.

The supported generated-Nix subset is documented in
[`docs/generated-nix-contract.md`](generated-nix-contract.md). That contract is
the boundary between Leanix graph claims and what Nix still witnesses by
parsing, evaluating, and building the generated backend artifact.

The renderer emits one output block per active system. Each block binds its own
`system` and `pkgs`, so package references such as
`self.packages.${system}."hello"` stay system-local. Synthetic default packages
are aliases to the first named package, matching the default-app shape instead
of duplicating the package builder.

Lockfile-backed `Input.flake` and local source inputs render as flake inputs.
Fixed-output `Input.source` values render as `builtins.fetchTree` bindings and
are excluded from the flake output argument set.

Pinned GitHub flake inputs render as explicit input attrsets. When a pin carries
`rev`, Leanix omits the branch/tag `ref` parsed from the URL because current Nix
rejects inputs that contain both a commit hash and a branch or tag name.

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

`leanix emit-artifact --out DIR` emits the proof-carrying CLI showcase artifact.
`leanix emit-service-artifact --out DIR` emits a second artifact shape from the
`ServiceProject` schema. Each artifact directory contains:

- `flake.nix`, the Nix backend artifact
- `leanix.manifest.json`, a machine-readable manifest

The manifest records the renderer version, active escape policy, source
reference, generated files, file hashes, systems, inputs, source trust classes,
pin policies, pin metadata, packages, app/check package references, checked
invariant names, and replay commands.

The maintained field contract is documented in
[`docs/artifact-manifest.md`](artifact-manifest.md). It classifies each field as
Rust-checked, Lean evidence, Nix-witnessed, or informational.

The current artifacts are proof-carrying in a deliberately narrow sense. Lean
checks schema invariants, package closure, finite acyclicity, source trust
requirements, and graph validation before emitting each artifact. The checked
flake carries the validation witness to the render boundary.

The authoritative generic artifact preflight now lives in the Rust e2e harness.
It reads `generatedFiles`, verifies that each declared file exists, reads
`fileHashes`, rejects tampered files with mismatched content hashes, checks that
replay commands are present, verifies strict artifact escape policy, and checks
input trust policy including pinned refs and lockfile witnesses. The current
hash is a Leanix-local content hash for tamper detection, not a cryptographic
signature scheme.

The service artifact deliberately has different manifest evidence: its
`sourceRef` points at `serviceProject`, its check is named `health`, and its
checked invariant names are `ServiceProject.*` rather than `CliProject.*`.

`leanix verify-artifact DIR` remains as a compatibility/showcase verifier. It
still checks the current showcase contract: expected systems, packages,
app/check references, default package alias, invariant names, input trust class,
source elaboration, and `nix flake check path:.` replay. The Rust e2e harness
checks the generic preflight for both the showcase and service artifacts, and
uses the Lean compatibility path for the showcase artifact. Nix remains the
external witness for evaluating and building the rendered flake; Leanix does
not claim to prove Nix evaluation.

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
- `BuildPlan.runPackageExecutableToOutput`, backed by
  `RunPackageExecutableArgs`
- `BuildPlan.leanPackageFromInputTree`, backed by
  `LeanPackageFromInputTreeArgs`

The wrapper, source-copy, text-file, executable-run, and Lean-package identities
carry named argument structures. Current validation rejects duplicate executable
arguments and missing package/input references before lowering to the backend
expression. `BuildPlan.installTextFile` can also carry typed `BuildText`, so
package and input references inside planned file content are visible to
validation.

Build-plan path validation is deliberately conservative. Source-like relative
paths, executable paths, and staging destinations must be non-empty, relative,
and free of `..` segments. Output destinations must be `$out` or live under
`$out/`. This catches common authoring mistakes before rendering, but it is not
a filesystem security model or a full path-normalization library.

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
term source of build semantics. The current inventory and reduction plan live
in [`docs/escape-hatches.md`](escape-hatches.md).

Escape-hatch validation is policy-driven. The default development policy keeps
these raw forms usable so existing examples remain ergonomic. Strict artifact
policy is applied before proof-carrying artifact emission and rejects raw shell
checks plus raw build-script forms such as `BuildExpr.runCommand`,
`BuildStep.installExecutableScript`, `BuildStep.writeFile`, and
`BuildStep.run`. This reduces the artifact trust surface; it does not prove the
behavior of external programs that typed commands invoke.

The policy matrix now has three contexts: development, CI, and strict artifact.
CI is a stricter validation mode for rejecting explicitly impure local sources
and raw shell escape hatches without changing the ergonomic development render
path. Strict artifacts additionally reject local development sources and
floating flake inputs without direct `rev` plus `narHash` evidence. See
[`docs/policy-matrix.md`](policy-matrix.md).

## CLI

`lake exe leanix` exposes the PoC commands (`Main.lean`):

- `leanix` — banner
- `leanix list-examples` — print registry example names
- `leanix render NAME --out FILE` — render a registry example
- `leanix render-example NAME --out FILE` — compatibility alias for registry
  rendering
- `leanix render-example --out FILE` — typed `hello`
- `leanix render-closure --out FILE` — typed package closure
- `leanix render-build-plan-text-file --out FILE` — `BuildPlan.installTextFile`
  lowered to a generated package
- `leanix render-build-plan-run-executable --out FILE` —
  `BuildPlan.runPackageExecutableToOutput` lowered to a generated package
- `leanix render-cli-schema --out FILE` — `CliProject` lowered to a flake
- `leanix render-formatter-schema --out FILE` — `FormatterProject` lowered to
  `formatter.${system}`
- `leanix render-library-schema --out FILE` — `LibraryProject` lowered to a
  package-first schema flake
- `leanix render-multi-app-schema --out FILE` — `MultiAppProject` lowered to a
  multi-app schema flake
- `leanix render-service-schema --out FILE` — `ServiceProject` lowered through
  `ValidatedSchema` to a daemon-style schema flake
- `leanix render-showcase --out FILE` — proof-carrying CLI closure showcase
- `leanix render-multi-system --out FILE` — graph-level two-system flake
- `leanix render-multi-system-schema --out FILE` — schema-authored two-system
  CLI project
- `leanix render-self --source URL --out FILE` — the self-check flake
- `leanix emit-artifact --out DIR` — proof-carrying showcase artifact
- `leanix emit-showcase-artifact --out DIR` — explicit showcase artifact alias
- `leanix emit-service-artifact --out DIR` — proof-carrying `ServiceProject`
  artifact
- `leanix emit-raw-check-artifact --out DIR` — negative strict-policy fixture
- `leanix verify-artifact DIR` — replay the current showcase artifact contract
- `leanix render-invalid-cli-schema --out FILE`
- `leanix render-invalid-formatter-schema --out FILE`
- `leanix render-invalid-library-schema --out FILE`
- `leanix render-invalid-multi-app-schema --out FILE`
- `leanix render-invalid-service-schema --out FILE`
- `leanix render-invalid-multi-system-schema --out FILE`
- `leanix render-invalid-build-plan-input-ref --out FILE`
- `leanix render-invalid-build-plan-run-executable-ref --out FILE`
- `leanix render-invalid-lean-package-input-ref --out FILE`
- `leanix render-invalid-build-plan-parent-path --out FILE`
- `leanix render-invalid-build-plan-absolute-destination --out FILE`
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

When `--nixparserlean-dir PATH` or `NIXPARSERLEAN_DIR` is provided, the harness
also runs optional nixparserlean interop. It renders selected examples under
`generated/interop-nixparserlean/`, asks nixparserlean for
`--desugar --format json`, checks declared parsed facts, and then runs
`--eval` on the top-level flake record. The parsed facts cover input
declarations, output families, active systems, package, app, dev-shell, check,
formatter names, selected default aliases, and the proof-carrying showcase
artifact flake. The artifact interop case also checks that the pinned
`nixpkgs` input fields are visible to the parser. This is a
syntax/desugar/top-level eval contract only; it does not apply the flake
`outputs` function to real inputs or prove semantic equivalence with Nix.

Run it from the repo root:

```sh
cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

The full harness remains the required local/CI gate. For faster development
loops, the same Rust runner also exposes focused paths:

```sh
cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --check-example hello
cargo run --locked --manifest-path e2e/runner/Cargo.toml -- --only hello --only showcase
```

`--check-example NAME` uses the public CLI example registry, renders that
example to `generated/flake.nix`, and runs `nix flake check path:./generated`.
`--only NAME` filters the normal valid render/check case list by registry name;
repeat it to run a small subset while debugging a renderer or schema change.

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
