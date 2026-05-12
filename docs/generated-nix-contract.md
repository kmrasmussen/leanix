# Generated Nix Backend Contract

Leanix emits Nix as a backend artifact. The checked Leanix graph is the
authoring and reasoning surface; generated Nix is the executable witness that
today's Nix tooling can evaluate and build the graph.

This document describes the supported generated-Nix subset as of
`formatVersion`/renderer version `leanix-poc-1`.

## Claims and Witnesses

Leanix claims:

- graph outputs were validated before rendering
- package/app/dev-shell/check/formatter references resolve by system
- source-like inputs follow the active policy
- raw escape hatches are explicit and policy-checkable
- artifact manifests and graph summaries are emitted from checked Leanix values

Nix still witnesses:

- the generated `flake.nix` parses as Nix
- flake outputs evaluate under real Nix
- nixpkgs packages and builders exist for the selected input revision
- derivations can be evaluated or built by the Nix daemon

NixParserLean interop witnesses only a narrower parser/evaluator contract. It
does not fetch real inputs or prove semantic equivalence with Nix.

## Inputs

Supported generated input forms:

- floating flake references, such as `github:NixOS/nixpkgs/nixos-unstable`
- pinned GitHub flake input attrsets with `type`, `owner`, `repo`, `rev`, and
  `narHash`
- non-flake local/development source inputs, emitted with a trust-boundary
  comment
- fixed-output source bindings rendered through `builtins.fetchTree`

Unsupported or intentionally shallow:

- arbitrary flake URL schemes beyond the forms currently rendered by
  `renderInput`
- applying generated `outputs` to fetched input values inside NixParserLean
- lockfile generation as a Leanix semantic claim

## Output Families

Supported output families:

- `packages.${system}.${name}`
- `apps.${system}.${name}`
- `devShells.${system}.${name}`
- `checks.${system}.${name}`
- `formatter.${system}`

The renderer emits one `let` block per active system. Package references are
system-local and render as `self.packages.${system}."name"`.

## Defaults

If a system has packages but no package named `default`, the renderer emits:

```nix
"default" = self.packages.${system}."<first package>";
```

If a system has apps but no app named `default`, the renderer emits:

```nix
"default" = self.apps.${system}."<first app>";
```

These defaults are aliases, not duplicated package or app definitions.

## Build Expressions

Supported package builder forms:

- `BuildExpr.nixpkgs`: select a package from `pkgs`
- `BuildExpr.inputPath`: expose a flake or source input path
- `BuildExpr.package`: refer to another checked package in the same system
- `BuildExpr.runCommand`: raw backend builder, allowed only by permissive
  policies
- `BuildExpr.runSteps`: structured builder with typed package/input references

Supported structured build steps:

- copy a source expression
- install text files
- install executable text scripts
- build a Lean project with `lake build`
- create directories
- copy files
- write files
- write typed text files
- mark files executable
- run a raw command step

`BuildPlan` values lower to these backend expressions after validation.

## Check Commands

Supported check command forms:

- `CheckCommand.packageExecutableToOutput`
- `CheckCommand.inputPathExists`
- `CheckCommand.rawShell`

`rawShell` is an escape hatch. CI and strict artifact policies reject it.

## Interop Coverage

The optional NixParserLean bridge renders into
`generated/interop-nixparserlean/` and currently checks:

- `hello`
- `cli-schema`
- `formatter-schema`
- `showcase`
- `multi-system`
- `self`
- `showcase-artifact`

Parsed-output contracts cover representative inputs, output families, active
systems, package/app/dev-shell/check names, formatter outputs, selected default
aliases, and pinned artifact input fields.

Interop failure messages distinguish:

- missing nixparserlean checkout
- stale or broken sibling checkout
- desugar/eval failure for generated Nix
- parsed-contract mismatch

## Generated Files

Generated files are ephemeral and should stay under `generated/`. The committed
contract lives in renderer code, goldens, docs, artifact manifests, graph
summaries, and Rust e2e assertions.

## Non-Goals

- full Nix semantic equivalence
- full nixpkgs builder modeling
- arbitrary Nix syntax as an authoring surface
- making NixParserLean mandatory for ordinary development
- treating generated Nix as the primary reasoning substrate
