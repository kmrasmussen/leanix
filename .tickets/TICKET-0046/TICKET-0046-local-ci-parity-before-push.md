# TICKET-0046: Local CI Parity Before Push

## Roadmap Source
This ticket comes from the GitHub Actions failure reported on 2026-05-12 and
the follow-up requirement that Leanix should not be easy to push when CI would
fail locally.

## Problem
The project already has a documented full local gate, but it is still possible
to push without running the same commands that GitHub Actions runs. A CI-only
failure on pinned input rendering made that gap visible.

## Goal
Add a lightweight, operator-friendly local CI parity workflow that runs the
same meaningful checks as `.github/workflows/ci.yml` before push.

## In Scope
- Add a repo-local script or command that runs the CI-equivalent gate.
- Make the command easy to use before `git push`.
- Consider an opt-in Git pre-push hook installer or documented hook snippet.
- Ensure the workflow runs:
  - `nix flake check`
  - `nix develop -c cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- Document the expected local command and how it relates to GitHub Actions.

## Out of Scope
- Enforcing hooks globally on the user's machine without consent.
- Replacing GitHub Actions.
- Adding external CI services.

## Acceptance Criteria
1. A single local command runs the same required checks as CI.
2. Documentation tells contributors to run it before push.
3. If a pre-push hook is added, it is opt-in and uses the same command.
4. The command is covered by a lightweight smoke check or direct execution in
   the ticket.

## Verification
- Run the new local CI parity command.

## Suggested Files
- `scripts/ci-local`
- `README.md`
- `roadmap/05-verification-strategy.md`
- `.tickets/TICKET-0046/TICKET-0046-local-ci-parity-before-push.md`

## Progress
- Ready.
