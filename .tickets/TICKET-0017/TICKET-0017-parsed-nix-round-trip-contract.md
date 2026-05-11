# TICKET-0017: Parsed Nix Round-Trip Contract

## Problem
The current nixparserlean bridge proves that selected Leanix-generated flakes
stay inside the parser/desugar/eval dialect, but it does not compare parsed
Nix back to the Leanix typed graph.

That leaves a gap: Leanix can render a flake that parses, while still losing
or reshaping typed output information in ways the current smoke test would not
notice.

## Goal
Add a round-trip contract for the supported renderer subset:

```text
Leanix typed graph -> flake.nix -> parsed Nix summary -> typed-output checks
```

The first version can compare a machine-readable summary rather than a full
AST isomorphism.

## In Scope
- Define the small output facts Leanix wants to recover from rendered Nix:
  systems, package names, default aliases, apps, dev shells, and checks.
- Add or consume a nixparserlean mode that emits those facts in a stable
  machine-readable format.
- Extend the Rust harness to compare the parsed summary against the Leanix
  case metadata for selected examples.
- Start with examples whose generated flakes are intentionally simple.

## Out of Scope
- Full Nix semantic equivalence.
- General Nix pretty-print round-tripping.
- Comparing arbitrary hand-written flakes.

## Acceptance Criteria
1. At least the hello, CLI schema, showcase, and multi-system examples have
   parsed-output summary checks.
2. A renderer change that drops a package, app, check, or default alias fails
   the round-trip check.
3. The parsed summary format is documented as an interop contract between the
   two repositories.
4. The check is still narrow about what it proves: generated flake shape, not
   real nixpkgs evaluation.
