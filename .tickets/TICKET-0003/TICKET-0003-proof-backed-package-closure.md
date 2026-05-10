# TICKET-0003: Proof-Backed Package Closure

## Problem
Leanix validates package references and cycles at runtime, but package closure is
not yet carried as proof data the way `CliProject.Valid` is.

## Goal
Move the package-closure boundary toward proof-carrying graph values.

## In Scope
- A proposition describing valid package closure for one system.
- A checked wrapper for package output sets or whole `Outputs`.
- Renderer entry points that can accept checked graph values.
- Small lemmas connecting checked graph values to rendered output assumptions.

## Out of Scope
- Full renderer correctness.
- Complete proof of Nix evaluation behavior.

## Acceptance Criteria
1. A checked package graph carries evidence that package refs resolve.
2. A checked package graph carries evidence, or a documented finite check, for
   acyclicity.
3. Existing valid and invalid closure examples still pass through Rust e2e.
