# TICKET-0049: Escape-Hatch Inventory and Reduction Plan

## Roadmap Source
This ticket materializes the backend-leakage slice from:

- `roadmap/02-milestones.md` Goal 1: Policy Matrix V1
- `roadmap/02-milestones.md` Goal 3: Agent-Legible Graph Summary V1
- `roadmap/03-workstreams.md` Workstream A: Typed Authoring Surface
- `roadmap/03-workstreams.md` Workstream B: Validation and Proof Evidence
- `roadmap/04-ticket-wave.md` TICKET-0049
- `docs/vision.md` Relationship To Nix

## Problem
Raw escape hatches are explicitly named, but the project does not yet expose a
single inventory of where they appear and which policy contexts allow them.
That makes backend leakage harder for an agent to inspect.

## Goal
Make backend leakage inspectable and reduce one common raw path.

## In Scope
- Enumerate raw build, raw check, raw file/script, and raw flake escape
  hatches.
- Expose escape-hatch usage in artifact manifests or graph summaries.
- Replace one repeated raw usage with a typed constructor if a clear pattern
  exists.
- Document which policies allow or reject each class.
- Add exact stderr coverage for at least one rejected escape-hatch class if not
  already covered by `TICKET-0044`.

## Out of Scope
- Removing all raw escape hatches.
- Pretending typed constructors can model arbitrary shell safely.
- Rewriting existing examples without a clear repeated pattern.

## Acceptance Criteria
1. Strict artifact or CI policy can reject at least one escape-hatch class.
2. An agent-facing summary or manifest names the escape hatches in use.
3. One raw usage is either replaced or deliberately justified in docs.
4. Docs classify each escape hatch by policy context.
5. `scripts/ci-local` passes.

## Verification
- `nix develop --command lake build`
- `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
- `scripts/ci-local`

## Suggested Files
- `Leanix/Core.lean`
- `Leanix/Validate.lean`
- `Leanix/Artifact.lean`
- `Leanix/Examples.lean`
- `e2e/runner/src/main.rs`
- `docs/escape-hatches.md`
- `blog/yyyy-mm-dd-hh-mm-escape-hatch-inventory.md`

## Progress
- Not started.
