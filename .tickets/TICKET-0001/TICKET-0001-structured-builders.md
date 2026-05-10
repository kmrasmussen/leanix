# TICKET-0001: Structured Builders

## Problem
`BuildExpr.runCommand` still carries raw shell script strings. This keeps the
prototype flexible, but it also lets important build semantics hide in strings.

## Goal
Introduce structured builder forms for the common operations Leanix should own
semantically.

## In Scope
- Typed builder nodes for copying sources, installing executable scripts,
  running commands, and building Lean projects.
- Renderer support for those nodes.
- Examples migrated away from hand-written shell where practical.
- Rust e2e coverage for each new builder form.

## Out of Scope
- Modeling all Nix builders.
- Eliminating shell scripts entirely.

## Acceptance Criteria
1. At least two existing examples use structured builder forms instead of raw
   scripts.
2. The generated flakes still pass through the Rust e2e harness.
3. Remaining shell escape hatches are explicit and documented.
