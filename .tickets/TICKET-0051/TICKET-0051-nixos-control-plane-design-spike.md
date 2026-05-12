# TICKET-0051: NixOS Control-Plane Design Spike

## Roadmap Source
This ticket materializes the first OS-control design slice from:

- `roadmap/02-milestones.md` Goal 5: NixOS Control-Plane Design Spike
- `roadmap/03-workstreams.md` Workstream G: Documentation and Project Narrative
- `roadmap/04-ticket-wave.md` TICKET-0051
- `docs/vision.md` The Desired World

## Problem
The long-term vision is operating-system control, but the current roadmap is
still mostly flake-shaped. Leanix needs a careful first step toward NixOS-like
structure without claiming to replace NixOS modules.

## Goal
Define the first tiny Leanix structure that points beyond flakes toward
NixOS-like control.

## In Scope
- Write a design note for one host/service relationship.
- Sketch typed fields such as host system, service package, port, user, check,
  source policy, and backend target.
- Define validation questions and agent questions before backend lowering.
- Identify the smallest future implementation ticket if the design is sound.
- State which parts remain delegated to NixOS/Nix.

## Out of Scope
- Implementing NixOS module generation.
- Modeling all NixOS options.
- Replacing existing host configuration.
- Deployment tooling.

## Acceptance Criteria
1. The design note includes one typed sketch.
2. The design note includes one backend-lowering sketch.
3. The note names at least five agent questions answerable at the Leanix layer.
4. The note states what remains delegated to NixOS/Nix.
5. A follow-up implementation ticket is created or explicitly deferred.

## Verification
- Documentation review against `docs/vision.md` and the current roadmap.

## Suggested Files
- `docs/nixos-control-plane-sketch.md`
- `roadmap/06-open-questions.md`
- `.tickets/README.md`
- `blog/yyyy-mm-dd-hh-mm-nixos-control-plane-design-spike.md`

## Progress
- Completed in this ticket.

## Plan
1. Write a design note for one host/service relationship.
2. Include a typed sketch and a backend-lowering sketch.
3. List validation and agent questions before backend lowering.
4. State what remains delegated to NixOS and Nix.
5. Explicitly defer or name the smallest follow-up implementation slice.

## Result
- Added `docs/nixos-control-plane-sketch.md`.
- Added the NixOS control-plane open question to
  `roadmap/06-open-questions.md`.
- Explicitly deferred implementation until a tiny `HostService V1` can validate
  host/service/package/check relationships and emit an agent-legible host
  summary.

## Verification Result
- Passed: documentation review against `docs/vision.md` and `roadmap/02-milestones.md`.
- Passed: `scripts/ci-local`.
