# TICKET-0006: Source Trust Model

## Problem
Leanix distinguishes flake inputs, hashed sources, and local sources, but the
trust model is still shallow.

## Goal
Make source provenance and trust boundaries explicit in the typed model.

## In Scope
- Separate local development sources from fixed-output fetched sources.
- Require hashes for fetch-like sources.
- Decide how lockfile-backed flake inputs should be represented.
- Renderer support for the supported source kinds.

## Out of Scope
- Implementing a lockfile manager.
- Replacing Nix's fetchers.

## Acceptance Criteria
1. Fetch-like source inputs cannot be rendered without a hash.
2. Local source inputs are clearly marked as development-only or impure.
3. At least one Rust e2e case covers source validation behavior.
