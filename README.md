# Leanix

Leanix is an adjacent project to `nixparserlean`.

**Mission:** Nix flakes as Lean-checked build graphs.

`nixparserlean` models existing Nix in Lean. Leanix starts from the other side:
what if flakes were typed first? Lean becomes the authoring language for
reproducible build graphs, and Nix interop becomes a backend.

Lean owns the typed model, validation, and rendering. Rust owns e2e harnesses,
subprocess orchestration, filesystem work, and generated-flake smoke tests.

Leanix now validates first-order package closure: package build expressions can
refer to other packages, and Lean rejects missing package references and package
dependency cycles before rendering Nix.

Leanix also has a first build-plan layer. `BuildPlan` describes common package
intentions before choosing the concrete Nix-shaped `BuildExpr`; it exposes
package and input references for validation, then lowers to the current
renderer backend. The first builder identities are typed constructors for known
nixpkgs packages, executable text wrappers, and input-tree copies, with named
argument records for the structured plans.

Artifact input policy is stricter than development rendering. Development flakes
can remain ergonomic with floating refs, while proof-carrying artifacts record
pinned revision/hash metadata or explicit lockfile witness metadata. Floating
flake inputs without either form of evidence are rejected by
`leanix verify-artifact`.

Artifact verification also reads manifest-declared generated files and file
hashes before replaying showcase checks, so tampered or missing generated files
are rejected directly by `leanix verify-artifact`.

Leanix also has its first typed output schema. `CliProject` lowers a typed
package/app/dev shell/check contract to ordinary flake outputs after validating
that the conventional defaults point at the project package.

The schema layer now covers more than the single default CLI shape. Use
`LibraryProject` when a package is the main output and the schema should enforce
default dev-shell/check conventions around it. Use `MultiAppProject` when one
package graph intentionally exposes several app outputs. Drop to raw `Flake`
and `Outputs` values when the project shape does not fit one of these
conventions yet.

Schema validation now has an explicit type boundary. Raw schemas become
`ValidatedSchema` values before they can be lowered through the validated-schema
API.

For `CliProject`, `ValidatedSchema` now carries proof fields for the schema
invariants: default output names, package references, and dev shell membership.

## Initial Hypothesis

A typed flake should make these things structural instead of conventional:

- supported systems
- flake inputs and source pins
- package, app, dev shell, check, and formatter outputs
- dependency graphs
- builder identity and arguments
- environment variables
- hash and provenance requirements

The first version is not a Nix replacement. It is a small Lean model that lets
us ask which flake invariants can be checked before evaluation or build time.

## First PoC

The smallest useful proof of concept is a typed hello flake:

```text
Lean value -> validation -> generated flake.nix -> nix build/check
```

That should include one package, one app, one development shell, and one check
for a single system. The point is to prove the shape of the workflow before
modeling the full Nix evaluator or store.

## Repository Layout

```text
Leanix/
  Core.lean      -- first typed flake/build graph model
Main.lean        -- tiny executable smoke target
docs/
  vision.md      -- project idea and design pressure
  roadmap.md     -- staged plan
  poc.md         -- first proof-of-concept target
flake.nix        -- Nix dev shell and build check
lakefile.lean    -- Lean package
```

## Quick Start

```sh
lake build
lake exe leanix
lake exe leanix render-example --out generated/flake.nix
lake exe leanix render-cli-schema --out generated/flake.nix
lake exe leanix render-library-schema --out generated/flake.nix
lake exe leanix render-multi-app-schema --out generated/flake.nix
nix flake check path:./generated
lake exe leanix render-self --source path:/home/kasper/projects/leanix --out generated/flake.nix
cargo run --locked --manifest-path e2e/runner/Cargo.toml
```
