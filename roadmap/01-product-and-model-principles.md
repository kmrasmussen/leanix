# Product and Model Principles

These principles should guide future work. They are constraints, not marketing
copy.

## Keep Lean as the Source of Truth

Leanix should not become a Nix string generator with a Lean wrapper. The source
of truth is the typed Lean value:

```text
Lean value -> validation/proof boundary -> generated backend artifact
```

Nix remains the first backend. It is not the authoring model.

## Prefer Small Executable Models

Every new concept should first appear as a small executable model with e2e
coverage. Proof obligations should attach to real pressure from the model, not
to speculative completeness.

Good next shapes:

- one formatter schema
- one service-like app schema
- one richer build-plan constructor
- one manifest verifier extension
- one stronger closure proof lemma

Poor next shapes:

- universal schema language
- general Nix evaluator
- complete nixpkgs builder coverage
- a large proof framework with no examples using it

## Keep Backend Boundaries Honest

Leanix currently has three layers:

- authoring layer: schemas and build plans
- checked graph layer: `ValidatedSchema`, `ValidatedFlake`,
  `CheckedPackageGraph`
- backend layer: `BuildExpr`, renderer, generated Nix

Future work should make these boundaries sharper. It should not bypass them for
short-term convenience.

## Make Escape Hatches Visible

Raw strings are acceptable only when they are named as escape hatches.

Current escape hatches:

- `BuildExpr.runCommand`
- `BuildStep.installExecutableScript`
- `BuildStep.writeFile`
- `BuildStep.run`
- `CheckCommand.rawShell`
- raw `Flake` and `Outputs` values outside schemas

The roadmap should gradually move common cases out of these escape hatches, but
it should not pretend they are gone.

## Rust Owns Effects and Harnesses

Lean should stay pure for the model, validation, proof witnesses, and renderer.
Rust should own:

- subprocess orchestration
- e2e harnesses
- filesystem crawling
- generated artifact inspection
- lockfile/cache workflows
- future CLI workflows that need OS effects

This keeps Lean code small and proof-oriented.

## Artifacts Need Evidence, Not Vibes

Proof-carrying artifacts should not just include a manifest. They should include
evidence that justifies each claim:

- checked invariant names should correspond to actual Lean boundaries
- input trust classes should have pin or lockfile evidence
- replay commands should be executable by the verifier
- generated files should be hashable and recorded

If an artifact cannot justify a claim, the manifest should use a weaker trust
class or the verifier should reject it.

## Interop Claims Must Stay Narrow

Leanix can benefit from `nixparserlean`, but the claim should remain precise:

- parse/desugar/eval of generated syntax is not full Nix semantics
- applying `outputs` to real flake inputs is a separate milestone
- `nix flake check` remains the backend witness for now

Every interop milestone should say exactly what was proven.
