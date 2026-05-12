# Leanix Roadmap

This folder is the operational roadmap for moving Leanix toward the long-term
vision in [docs/vision.md](../docs/vision.md): a typed control plane over Nix
where agents can reason about infrastructure from Leanix structures before Nix
realizes the backend artifact.

The roadmap is not a broad replacement plan for Nix. Nix remains the practical
backend. Leanix should advance by building small vertical slices where typed
authoring, checked graph evidence, explicit policy, generated Nix, Rust-owned
verification, and narrow interop feedback all connect.

## Current Horizon

The active horizon starts on 2026-05-12 and targets the next four weeks of work.

The main objective is:

```text
make one narrow typed-flake subset agent-legible, policy-aware, and
artifact-verifiable end to end
```

That means prioritizing:

- policy contexts for development, CI, and strict artifacts
- explicit raw escape-hatch inventory and rejection rules
- machine-readable summaries of the checked graph
- artifact manifests whose claims are checked by Rust or backed by Lean evidence
- generated Nix contracts that remain narrow and independently checked
- one first NixOS-control design slice that shows how the approach can grow
  beyond flakes without pretending to replace NixOS yet

## Read Order

1. [00-current-state.md](00-current-state.md) describes the current checkout.
2. [01-product-and-model-principles.md](01-product-and-model-principles.md)
   states the design rules that keep the project coherent.
3. [02-milestones.md](02-milestones.md) defines SMART goals for the current
   horizon.
4. [03-workstreams.md](03-workstreams.md) breaks the roadmap into engineering
   ownership tracks.
5. [04-ticket-wave.md](04-ticket-wave.md) proposes the next implementation
   slices.
6. [05-verification-strategy.md](05-verification-strategy.md) explains the
   gates every meaningful change should pass.
7. [06-open-questions.md](06-open-questions.md) lists decisions that should
   remain explicit.

## Roadmap Discipline

Every roadmap item should say:

- what structure becomes more explicit in Leanix
- what can be checked before rendering
- what evidence is emitted or verified
- what Nix still witnesses as the backend
- what an agent can now answer without reading generated Nix

If a change does not improve one of those points, it should probably stay out
of the near-term roadmap.
