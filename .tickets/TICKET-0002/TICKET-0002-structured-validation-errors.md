# TICKET-0002: Structured Validation Errors

## Problem
Validation currently reports `Except String`. This is easy to start with, but
it makes Rust e2e tests assert success/failure rather than exact failure kinds.

## Goal
Replace string validation failures with structured Lean error types.

## In Scope
- A `ValidateError` inductive for graph validation.
- A schema validation error type or shared error layer.
- Human-readable renderers for CLI output.
- Rust e2e assertions for exact expected errors.

## Out of Scope
- Source spans or diagnostics for a full language frontend.
- Localization or rich terminal formatting.

## Acceptance Criteria
1. Missing package references and package cycles have distinct error variants.
2. CLI output remains readable.
3. Rust e2e validates at least two exact error classes.

## Progress
- Added `ValidateError` for graph validation failures.
- Added `SchemaError` for `CliProject` schema validation failures.
- Kept CLI messages human-readable through `ToString` renderers.
- Updated the Rust e2e harness to compare exact stderr for missing package,
  package cycle, and invalid CLI schema cases.
