# Open Questions

These questions should stay explicit. They are not blockers for the next work,
but they shape the architecture.

## How General Should Schemas Become?

Leanix now has multiple schemas, but it should avoid a premature universal
schema language.

Questions:

- Should schemas remain hand-written Lean structures?
- When should shared validation helpers become a schema combinator library?
- Should schema docs become a formal catalog?
- Should raw `Flake` remain the only escape hatch for unusual output shapes?

Working stance:

Keep schemas concrete until at least three more real conventions expose repeated
patterns.

## How Far Should BuildPlan Move Away From Nix?

`BuildPlan` is backend-neutral in intent but still lowers to `BuildExpr`.

Questions:

- Which plan constructors are genuinely backend-neutral?
- Should `BuildPlan` eventually replace `BuildExpr` as the package field?
- Should packages store both source plan and lowered backend expression?
- How should plan validation carry proof evidence?

Working stance:

Keep `BuildExpr` as the backend representation for now. Move package authoring
toward `BuildPlan` where examples prove the need.

## Where Should Artifact Verification Live?

The current verifier is Lean CLI code with simple string checks.

Questions:

- Should manifest parsing and file hashing move to Rust?
- Should Lean emit the manifest and Rust verify it?
- Should artifact verification become a separate Rust command?
- How much JSON machinery is acceptable in Lean?

Working stance:

Lean should emit artifacts from checked values. Rust should likely own generic
artifact verification once file hashing and directory crawling become central.

## What Is the Right Proof Target for Package Closure?

`ReferencesResolve` and `NoFuelBoundedCycles` are named, but still checker-backed.

Questions:

- Is topological sort the best proof-friendly algorithm?
- Should reachability be defined over package names or package records?
- Should duplicate package names be part of the graph property or a separate
  precondition?
- How much soundness/completeness should be proven before adding more features?

Working stance:

Define the graph relation first, then connect the current checker to it one
lemma at a time.

## How Strict Should Artifact Policy Be?

Artifacts now reject floating flake inputs without pin or lockfile evidence.

Questions:

- What exact lockfile node metadata is enough evidence?
- Should artifact policy also reject raw shell?
- Should artifact policy reject impure local sources?
- Should development policy warn but not fail?

Working stance:

Artifacts should be strict and explicit. Development should stay ergonomic.

## How Should NixParserLean Interop Evolve?

Current interop is useful but narrow.

Questions:

- Should nixparserlean expose a dedicated summary mode for Leanix?
- Should Leanix eventually import a shared Lean AST package?
- Should parsed-output contracts cover source inputs and lockfile metadata?
- When, if ever, should interop apply the `outputs` function to real inputs?

Working stance:

Keep interop Rust-owned and contract-based until the shared shape stabilizes.

## How Much CLI Should Lean Own?

The Lean executable currently renders examples and verifies the showcase
artifact.

Questions:

- Should example listing and case filtering stay in Lean?
- Should subprocess orchestration move to Rust CLI tooling?
- Should `leanix check` exist, or should e2e remain developer-only?

Working stance:

Lean can own pure rendering and simple artifact emission. Rust should own
subprocess-heavy workflows.
