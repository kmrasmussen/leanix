# Proposed Next Ticket Wave

This is a candidate backlog wave after the completed `TICKET-0025` state. These
are written as concrete tickets so they can be copied into `.tickets/` when the
project is ready.

## TICKET-0026: Formatter Schema

Problem:

Flakes commonly expose formatter outputs, but Leanix currently models packages,
apps, dev shells, and checks only.

Goal:

Add the first typed formatter output model and one schema path that can expose a
formatter convention.

Scope:

- add `Formatter` or equivalent output type
- render formatter outputs
- validate formatter package references
- add one valid example and one invalid e2e case
- update schema docs

Acceptance:

- generated flake exposes `formatter.${system}`
- invalid formatter package reference fails before rendering
- e2e passes `nix flake check`

## TICKET-0027: BuildPlan Install File and Copy Source Constructors

Problem:

`BuildPlan` exists, but many structured build operations are still authored
directly as backend `BuildStep` values.

Goal:

Move common file/source operations into build-plan constructors with named
arguments.

Scope:

- add build-plan constructors for copying source trees and installing text files
- migrate one existing example from direct `BuildExpr.runSteps`
- validate package/input refs before lowering
- add invalid e2e case for missing input

Acceptance:

- at least one package is authored entirely through build plans
- generated golden is stable or intentionally updated
- missing input in a plan fails with exact stderr

## TICKET-0028: General Artifact Verifier Skeleton

Problem:

`verify-artifact` still verifies the showcase artifact contract directly.

Goal:

Create a general artifact verification layer that can inspect generated files,
manifest fields, and replay commands beyond the showcase.

Scope:

- introduce Rust-owned or Lean-owned manifest reading decision
- check generated file existence from manifest
- record and verify file hashes
- add tampered artifact e2e fixture
- keep showcase verifier behavior intact during migration

Acceptance:

- verifier rejects a tampered `flake.nix`
- verifier rejects a missing generated file
- showcase artifact still verifies

## TICKET-0029: Lockfile Witness Metadata

Problem:

Artifact manifests can record pinned refs, but they cannot yet justify
lockfile-backed floating inputs.

Goal:

Define and verify the first lockfile witness metadata.

Scope:

- add lockfile witness fields to `ArtifactInput`
- decide minimal node metadata to record
- add verifier checks for witness presence
- add e2e case for lockfile-backed input
- document development versus artifact policy

Acceptance:

- pinned refs and lockfile-backed refs are separate trust classes
- floating refs without witness still fail artifact verification
- docs state what Leanix does not resolve automatically

## TICKET-0030: Package Closure Graph Relation

Problem:

`PackageClosure.Valid` now has named properties, but those properties are still
constructed from boolean checks.

Goal:

Introduce an explicit graph relation over package names as the next proof
target.

Scope:

- define package-edge relation
- define reachability or acyclicity proposition
- connect reference-resolution boolean to the named property
- update `docs/closure-proof-strategy.md`

Acceptance:

- examples still elaborate without brittle proof terms
- cycle e2e stays exact
- docs explain what is proven and what is still checker-backed

## TICKET-0031: Parsed Nix Summary Contract

Problem:

Leanix's nixparserlean interop uses JSON string fragments instead of a stable
summary contract.

Goal:

Make generated-Nix interop checks less fragile and more meaningful.

Scope:

- define desired parsed summary shape
- update Leanix e2e expectations
- make sibling nixparserlean changes if needed
- cover inputs and output aliases

Acceptance:

- `--nixparserlean-dir` e2e checks structured facts, not broad string fragments
- docs keep the interop claim narrow

## TICKET-0032: Raw Escape Hatch Policy

Problem:

Raw shell and raw graph escape hatches are explicit, but there is no policy mode
that can reject them for strict artifacts.

Goal:

Introduce policy values for development versus artifact contexts.

Scope:

- define policy type
- validate raw shell/check/build-step use according to policy
- keep development examples ergonomic
- make artifact policy stricter
- add rejection e2e for a raw shell check under strict policy

Acceptance:

- `CheckCommand.rawShell` remains usable in development
- strict artifact policy rejects at least one raw escape hatch
- docs list policy behavior

## TICKET-0033: CLI Example Registry

Problem:

The CLI has many specific `render-*` commands, which is useful for e2e but
awkward for users.

Goal:

Add a small example registry without removing existing commands.

Scope:

- `leanix list-examples`
- `leanix render-example-name NAME --out FILE`, or a similarly simple command
- keep old commands for compatibility
- update docs and e2e

Acceptance:

- all existing examples are discoverable
- one e2e path uses the registry command
- old commands still pass
