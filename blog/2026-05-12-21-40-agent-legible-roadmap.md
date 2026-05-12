# Agent-Legible Roadmap

The roadmap has been reframed around the long-term Leanix vision: a typed
control plane over Nix.

The point is not to replace Nix in the near term. Nix remains the backend that
realizes builds, flakes, nixpkgs integration, and eventually NixOS integration.
Leanix should own the layer above that: typed intent, checked relationships,
policy, artifact evidence, and agent-legible summaries.

This changes the roadmap emphasis. The next work should not be "more Nix
surface area" for its own sake. It should build a narrow vertical slice where an
agent can answer real questions from Leanix structures without reading generated
Nix:

- what depends on this input
- which sources are pinned, lockfile-backed, local, or impure
- where raw escape hatches remain
- which graph claims are backed by Lean evidence
- which artifact claims Rust verifies
- which facts are still delegated to Nix as the backend witness

The new four-week horizon starts with the remaining policy matrix slice, then
pushes into artifact contract documentation, graph summaries, generated-Nix
backend contracts, and a first NixOS-control design spike.
