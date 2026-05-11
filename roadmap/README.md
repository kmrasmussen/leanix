# Leanix Future Roadmap

This folder is the forward-looking roadmap for Leanix after the first typed
flake proof of concept.

The older [docs/roadmap.md](../docs/roadmap.md) records phase status. This
folder is more operational: it describes the current state, the design pressure
that should guide the next work, concrete milestones, proposed ticket waves, and
verification gates.

## Read Order

1. [00-current-state.md](00-current-state.md) describes what is true in the
   current checkout.
2. [01-product-and-model-principles.md](01-product-and-model-principles.md)
   states the design rules that should keep the project coherent.
3. [02-milestones.md](02-milestones.md) defines the next concrete milestones.
4. [03-workstreams.md](03-workstreams.md) breaks the roadmap into engineering
   tracks.
5. [04-ticket-wave.md](04-ticket-wave.md) proposes the next backlog wave.
6. [05-verification-strategy.md](05-verification-strategy.md) explains the
   gates every meaningful change should pass.
7. [06-open-questions.md](06-open-questions.md) lists decisions that should
   remain explicit.

## Current Direction

Leanix should now move from "small PoC with typed outputs" to "small typed
flake authoring system with proof-carrying artifacts." The right next work is
not breadth across all of Nix. It is deeper ownership of a narrow subset:

- typed authoring schemas for common project shapes
- backend-neutral build plans that lower to Nix
- stronger graph and schema evidence in Lean
- artifact manifests with reproducibility evidence
- Rust-owned e2e and interop checks
- narrow parsed-Nix feedback from `nixparserlean`

The main risk is pretending Leanix is more complete than it is. The roadmap
therefore keeps escape hatches explicit and makes proof, artifact, and interop
claims narrow.
