# TICKET-0044: Policy Matrix for CI and Impure Sources

## Roadmap Source
This ticket materializes the next policy-layer slice from:

- `roadmap/02-milestones.md` Milestone 7: Policy Layer
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0044
- `roadmap/06-open-questions.md` How Strict Should Artifact Policy Be?

## Problem
Leanix now has development and strict artifact escape policies, plus input pin
policy, but there is no coherent matrix for CI and impure/local source rules.

## Goal
Define a small policy matrix for development, CI, and strict artifact contexts.

## In Scope
- Extend policy values or add a policy record for CI.
- Define behavior for floating flake refs, impure local sources, raw shell, and
  missing artifact evidence.
- Add e2e rejection cases for at least one CI-only or artifact-only rule.
- Keep development examples ergonomic.
- Update docs and manifests where policy is recorded.

## Out of Scope
- Warning infrastructure unless it falls out naturally.
- Full supply-chain attestation.
- Removing development escape hatches.

## Acceptance Criteria
1. Policy behavior is explicit in code and docs.
2. Development examples stay ergonomic.
3. At least one impure/local source policy rejection has exact stderr coverage.
4. Artifact manifests still record the active policy.
5. CI policy is documented even if it starts as a narrow validation mode.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Artifact.lean`
- `Leanix/Examples.lean`
- `Main.lean`
- `e2e/runner/src/main.rs`
- `docs/poc.md`
- `blog/yyyy-mm-dd-hh-mm-policy-matrix-ci-impure-sources.md`

## Progress
- Not started.
