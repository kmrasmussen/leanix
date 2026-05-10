# TICKET-0004: Golden Renderer Tests

## Problem
The Rust harness checks generated flakes by running Nix, but it does not yet
protect renderer output shape from accidental churn.

## Goal
Add committed golden outputs for selected generated flakes.

## In Scope
- A golden fixture directory under `e2e/`.
- Rust harness support for comparing generated output to expected text.
- A clear update workflow for intentional renderer changes.
- Golden cases for hello, typed closure, and CLI schema examples.

## Out of Scope
- Full Nix formatting or semantic normalization.
- Snapshotting every generated artifact.

## Acceptance Criteria
1. Rust e2e fails when selected rendered flakes change unexpectedly.
2. The update workflow is documented.
3. Nix checks still run after golden comparison passes.
