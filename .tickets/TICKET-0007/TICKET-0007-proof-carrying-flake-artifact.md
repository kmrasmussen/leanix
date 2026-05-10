# TICKET-0007: Proof-Carrying Flake Artifact

## Problem
Leanix can render checked Lean values to `flake.nix`, and the Rust harness can
ask Nix to evaluate the result. That proves the generated flake works today, but
it does not yet produce a durable artifact that explains what Lean checked, what
Nix received, and which reproducibility promises were carried across the
boundary.

If Leanix wants to make "Nix flakes as Lean-checked build graphs" feel real, the
output should be more than a generated file. It should be a bundle: source,
rendered Nix, typed graph metadata, validation evidence, and an executable
verification path.

## Goal
Define a proof-carrying flake artifact format for Leanix.

A Leanix artifact is a directory that contains:

- the rendered `flake.nix`
- a machine-readable `leanix.manifest.json`
- the Lean source or source reference that produced it
- a record of checked invariants
- enough metadata for the Rust harness to replay the verification

The audacious version is that a user can inspect the artifact and see:

```text
Lean typed source -> validated graph/proofs -> rendered flake.nix -> Nix check witness
```

## Why This Is Ambitious
This ticket turns Leanix from a renderer into a small proof-carrying build graph
system. It creates a boundary where Lean owns typed claims and Rust owns
real-world replay: filesystem layout, subprocesses, Nix evaluation, build logs,
and future cache/signature checks.

It also creates a practical bridge toward mature tooling. Once artifacts exist,
CI, examples, golden tests, provenance checks, and future lockfile work can all
share one concrete contract.

## In Scope
- A first `leanix.manifest.json` schema emitted by the CLI.
- Manifest fields for package names, systems, inputs, source trust classes,
  checked invariants, renderer version, and generated files.
- A CLI command that writes an artifact directory, not just a single flake.
- Rust e2e support that verifies the artifact by reading the manifest, checking
  expected files, running `nix flake check`, and asserting declared invariants
  match the generated output.
- One showcase artifact under `examples/` with committed expected files.
- A design note explaining what is proof, what is validation evidence, and what
  is only an external Nix witness.

## Out of Scope
- Cryptographic signing.
- Binary cache publication.
- Full proof of Nix evaluation semantics.
- Replacing `flake.lock`.
- A stable public artifact format before the prototype earns it.

## Acceptance Criteria
1. `lake exe leanix emit-artifact --out generated/showcase-artifact` writes a
   directory with `flake.nix` and `leanix.manifest.json`.
2. The manifest records at least systems, package names, app/check references,
   source trust classes, and checked invariant names.
3. The Rust e2e harness verifies the artifact by reading the manifest and
   running `nix flake check` on the artifact directory.
4. The proof-carrying CLI closure showcase has committed expected artifact
   files under `examples/`.
5. Documentation states clearly which claims are checked in Lean, which are
   replayed by Rust, and which are delegated to Nix.

## First Slice
Start deliberately small:

1. Define a Lean `ArtifactManifest` record for one system.
2. Render it to JSON for the existing proof-carrying CLI closure showcase.
3. Add `emit-showcase-artifact --out DIR`.
4. Teach Rust e2e to assert that every manifest package appears in
   `flake.nix` and that `nix flake check path:DIR` succeeds.

That first slice should not attempt cryptographic proof objects. The point is
to establish the artifact boundary and make later proofs and provenance checks
have a real home.

