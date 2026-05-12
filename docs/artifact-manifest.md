# Artifact Manifest Contract

`leanix.manifest.json` is the evidence contract for generated Leanix artifact
directories.

Lean emits the manifest from checked values. Rust owns the generic filesystem
and manifest preflight. Nix remains the backend witness for evaluating and
checking the generated `flake.nix`.

## Schema

Current schema:

- `formatVersion`: `1`
- `rendererVersion`: `leanix-poc-1`

The Rust verifier rejects missing or unsupported schema fields before checking
artifact contents.

## Field Contract

| Field | Status | Meaning |
| --- | --- | --- |
| `formatVersion` | Rust-checked | Manifest schema version. Currently must be `1`. |
| `rendererVersion` | Rust-checked | Emitting renderer identity. Currently must be `leanix-poc-1`. |
| `escapePolicy` | Rust-checked | Active policy. Generic artifact verification requires `strict-artifact`. |
| `sourceRef` | Informational | Human-oriented source pointer for the Leanix value or schema. |
| `generatedFiles` | Rust-checked | Every listed file must exist in the artifact directory. |
| `fileHashes` | Rust-checked | Every listed file hash must match the generated file content. |
| `systems` | Lean evidence | Systems are emitted from checked Leanix output values. |
| `inputs` | Rust-checked policy | Trust classes and pin evidence are checked by the generic verifier. |
| `packages` | Lean evidence | Package names/builders are emitted from checked package graph values. |
| `apps` | Lean evidence | App package references are emitted after validation. |
| `checks` | Lean evidence | Check package references are emitted after validation. |
| `checkedInvariants` | Lean evidence names | Names the checked boundaries carried into artifact emission. |
| `replayCommands` | Rust-checked shape, Nix-witnessed execution | Must be non-empty; actual backend replay is still performed by Nix/Lean commands. |

## Trust Boundary

The manifest is not a proof of Nix evaluation semantics. It is a compact record
of what Leanix checked, what Rust can verify from the artifact directory, and
what Nix should replay as the backend witness.

If a field makes a claim that Rust does not verify directly, the field should
either correspond to checked Lean evidence or be documented as informational.
