# Verification Strategy

Leanix should keep a strict verification culture. The project is still small
enough that every meaningful change can pass the full local gate.

## Default Gate

After Lean changes:

```sh
nix develop --command lake build
```

After renderer, CLI, generated-flake, artifact, interop, or e2e changes:

```sh
nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

These are the default gates for ticket completion.

## Optional NixParserLean Gate

When touching generated Nix shape, parsed-output contracts, or interop:

```sh
nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml -- \
  --nixparserlean-dir ../nixparserlean
```

or:

```sh
NIXPARSERLEAN_DIR=../nixparserlean \
  nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml
```

This gate is optional because it depends on a sibling checkout. Failures should
be interpreted carefully:

- Leanix generated invalid or unsupported Nix
- the parsed contract changed
- the sibling nixparserlean checkout is dirty or broken

Do not overstate this gate. It verifies a narrow syntax/desugar/top-level eval
contract, not full Nix semantic equivalence.

## Golden Fixtures

Golden fixtures should be used when output text shape matters:

- simple hello flake
- closure flake
- schema-generated flakes
- multi-system flakes
- pinned input rendering
- env rendering
- proof-carrying showcase artifact

When a golden changes, the commit should explain why the generated Nix changed.

## Invalid Cases

Every new validation rule needs an invalid e2e case with exact stderr.

Good invalid cases:

- missing package ref
- missing input ref
- duplicate env var
- unsupported builder/env combination
- invalid schema convention
- floating artifact input under artifact policy
- impure local source under CI policy
- duplicate build-plan argument
- typed check reference failure

Exact stderr matters because it proves the failure is happening at the intended
boundary.

## Artifact Verification

Artifact changes should verify through the Rust-owned generic preflight in the
e2e harness:

- generated files exist
- file hashes match manifest declarations
- replay commands are present
- pin/trust policy is justified from manifest input data
- strict artifact escape policy is present
- multiple artifact shapes can pass the same generic preflight

The Lean CLI command `leanix verify-artifact` remains as the showcase
compatibility verifier. It checks the current showcase contract and replay:

- manifest fields match the expected showcase artifact contract
- replay commands still work
- `nix flake check path:.` succeeds inside the artifact directory

Future artifact verifier work should add:

- manifest schema version checks
- a public Rust operator command for generic artifact verification

## Ticket Completion Checklist

For each substantial ticket:

- update the ticket file with plan and progress
- add or update e2e coverage
- run `lake build`
- run the Rust e2e harness
- write a dated blog note for meaningful project steps
- update reference docs if current behavior changed
- commit the ticket slice
- push regularly

## CI Direction

GitHub Actions and local pre-push checks share the same required gate:

- `nix flake check`
- `nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml`

Run the local parity command before pushing:

```sh
scripts/ci-local
```

For local enforcement, install the opt-in Git hook:

```sh
scripts/install-pre-push-hook
```

The hook delegates to `scripts/ci-local`, so local pre-push behavior and CI stay
anchored on one command. CI should not depend on generated artifacts that are
ignored locally unless the workflow creates them fresh.
