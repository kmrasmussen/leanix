# TICKET-0045: Pinned Flake Input CI Regression

## Roadmap Source
This ticket comes from the GitHub Actions failure reported on 2026-05-12.

## Problem
CI fails in the Rust e2e harness during the `pinned flake input` case:

```text
input ... contains both a commit hash (...) and a branch/tag name ('nixos-unstable')
```

Leanix renders a pinned GitHub flake input with both `ref` and `rev` when the
source URL includes a branch/tag and `SourcePin.rev?` is present. Current Nix
rejects that shape.

## Goal
Render pinned GitHub flake inputs in a Nix-compatible shape and keep the local
e2e gate aligned with CI behavior.

## In Scope
- Update the renderer so GitHub flake inputs with `rev?` do not also render
  the URL-derived branch/tag `ref`.
- Regenerate the pinned-input golden fixture.
- Run the full local verification gate.
- Document the behavior if the source-pin docs mention explicit `ref` plus
  `rev`.

## Out of Scope
- Resolving or fetching pins automatically.
- Changing the `SourcePin` data model.
- Adding Git hooks or CI parity tooling; that is tracked separately in
  `TICKET-0046`.

## Acceptance Criteria
1. `render-pinned-inputs` no longer emits both `ref` and `rev` for the same
   GitHub input.
2. The pinned-input e2e case passes `nix flake check`.
3. The full Rust e2e harness passes locally.
4. The fix is committed and pushed.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`

## Suggested Files
- `Leanix/Render.lean`
- `e2e/golden/pinned-inputs.flake.nix`
- `.tickets/TICKET-0045/TICKET-0045-pinned-flake-input-ci-regression.md`

## Progress
- Completed in this ticket.

## Plan
- Reproduce the CI failure locally through the pinned-input e2e case.
- Render pinned GitHub inputs with `rev` and `narHash`, but without the
  URL-derived branch `ref` when `rev` is present.
- Regenerate the pinned-input golden and proof-carrying artifact fixture.
- Run the GitHub Actions equivalent local gates before push.

## Result
- Updated `renderGithubInput` so `ref` is only emitted when there is no explicit
  `rev`.
- Regenerated `e2e/golden/pinned-inputs.flake.nix`.
- Regenerated the proof-carrying showcase artifact fixture so its pinned
  `nixpkgs` input matches the renderer.
- Added `TICKET-0046` to track local CI parity before push as a separate
  follow-up.

## Verification Result
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `nix flake check`
