# TICKET-0022: Artifact Verifier CLI

## Problem
The proof-carrying artifact exists, and the Rust e2e harness verifies parts of
its manifest contract. But users do not yet have a direct `leanix` command for
verifying an artifact directory outside the test harness.

That keeps artifact replay as internal test logic instead of a usable boundary.

## Goal
Add a `leanix verify-artifact DIR` command owned by Rust or a small dedicated
verifier layer.

## In Scope
- Read `leanix.manifest.json`.
- Check that declared generated files exist.
- Check that packages, apps, checks, systems, and invariant names are coherent
  with the generated `flake.nix` under the current supported subset.
- Run declared replay commands where appropriate.
- Share verifier logic with the e2e harness instead of duplicating ad hoc
  checks.

## Out of Scope
- Cryptographic signatures.
- Stable public artifact format guarantees.
- Proving Nix evaluation.

## Acceptance Criteria
1. `leanix verify-artifact examples/proof-carrying-cli-closure/artifact`
   succeeds.
2. Removing a declared file, package, or invariant causes a clear failure.
3. The Rust e2e harness calls the same verifier path.
4. Artifact docs explain what verification checks locally and what remains
   delegated to Nix.

## Plan
1. Add a narrow `leanix verify-artifact DIR` command for the current showcase
   artifact format.
2. Have the command check manifest/file/package/reference/invariant facts and
   run the replay commands Leanix owns today.
3. Replace the Rust harness's private manifest verifier with calls to the CLI
   verifier.
4. Add direct positive and negative verification runs before marking complete.

## Progress
- Added `leanix verify-artifact DIR`.
- The verifier checks the current showcase artifact files, expected package and
  invariant facts, default package alias, and replay commands.
- The Rust e2e harness now calls the verifier for both generated and committed
  showcase artifacts.
- Documented the verifier in the PoC and showcase docs.
- Verified the committed showcase artifact directly.
- Verified a negative copied artifact fails when an expected invariant is
  removed.
- Verified the full Rust e2e harness passes with the verifier in the artifact
  case.
