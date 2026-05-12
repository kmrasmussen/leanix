# Escape Hatch Inventory

Leanix keeps escape hatches explicit. They are useful while the typed surface is
small, but an agent should be able to see when a graph depends on backend-shaped
behavior.

## Inventory

| Escape hatch | Where it lives | Development | CI | Strict artifact |
| --- | --- | --- | --- | --- |
| Raw check shell | `CheckCommand.rawShell` | Allowed and reported | Rejected | Rejected |
| Raw derivation builder | `BuildExpr.runCommand` | Allowed and reported | Rejected | Rejected |
| Raw build step command | `BuildStep.run` | Allowed and reported | Rejected | Rejected |
| Raw executable script text | `BuildStep.installExecutableScript` | Allowed and reported | Rejected | Rejected |
| Raw file write | `BuildStep.writeFile` | Allowed and reported | Rejected | Rejected |
| Raw `Flake`/`Outputs` authoring | Direct `Flake` values instead of schemas | Allowed after graph validation | Allowed after graph validation | Allowed after graph validation |

The first five are backend escape hatches because they introduce shell or raw
file/script behavior that Leanix does not model deeply. The last one is an
authoring escape hatch: raw flakes skip schema-specific conventions, but still
must pass `Flake.validateChecked` before rendering through normal CLI paths.

## Agent Visibility

`leanix summarize NAME --out FILE` exposes backend escape hatches in the
`rawEscapeHatches` array. Each entry names:

- the system
- the owner, such as `check build` or `package foo`
- the rejected escape class, such as `raw shell command` or `run step ...`

This means an agent can answer "what would block CI or strict artifact policy?"
without reading generated Nix.

## Current Reduction

The shared `helloCheck` no longer uses `CheckCommand.rawShell`. It now uses the
typed `CheckCommand.packageExecutableToOutput` form:

```lean
command := .packageExecutableToOutput {
  packageName := "hello"
  executable := "hello"
  arguments := ["--version"]
}
```

That removes the repeated raw shell pattern from the ordinary hello, CLI,
library, formatter, and related examples. A separate `rawHelloCheck` remains as
an intentional fixture for strict artifact policy rejection.

## Policy Notes

Development policy is permissive so examples can still model unsupported
backend behavior while the typed surface grows. CI and strict artifact policies
reject backend escape hatches because those contexts should not silently depend
on raw shell or raw build-script behavior.

Strict artifact policy also rejects local/impure sources and floating flake
inputs without direct pin evidence. CI currently rejects impure local sources
while still allowing floating flake inputs so local development ergonomics and
artifact trust can evolve separately.
