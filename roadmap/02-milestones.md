# SMART Milestones

This file defines the current four-week roadmap horizon from 2026-05-12 through
2026-06-09.

The long-term vision is agent-legible infrastructure: Leanix should let an
agent reason about build and operating-system structure from typed Leanix values
instead of reverse-engineering generated Nix. The near-term route is a narrow,
measurable vertical slice, not broad Nix or NixOS replacement.

## Goal 1: Policy Matrix V1

Deadline: 2026-05-19.

Specific:

- Define explicit policy contexts for development, CI, and strict artifacts.
- Specify how each context treats floating flake refs, lockfile witnesses,
  fixed-output sources, local development sources, impure local sources, raw
  build steps, and raw shell checks.
- Encode the policy in Lean validation or artifact emission paths, not only in
  prose.

Measurable:

- `TICKET-0044` is completed.
- At least one CI-only or artifact-only rejection has an exact stderr e2e case.
- Artifact manifests still record the active policy.
- `docs/poc.md` or a dedicated policy reference names every policy class.

Achievable:

- The project already has development and strict artifact escape policies,
  input trust classes, and Rust e2e rejection cases.

Relevant:

- Policy is the line between ergonomic development and claims that an agent can
  safely trust in CI or artifacts.

Time-bound acceptance:

- By 2026-05-19, `nix develop --command lake build` and
  `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
  pass with the new policy cases.

## Goal 2: Artifact Evidence Contract V1

Deadline: 2026-05-26.

Specific:

- Document the manifest schema and version policy for generated artifacts.
- Make the Rust generic verifier reject missing or mismatched required manifest
  fields, not only tampered files.
- Move at least one replay check from showcase-specific expectations to
  manifest-declared data.

Measurable:

- At least two artifact shapes verify through the same Rust verifier path.
- The verifier checks generated files, file hashes, replay command metadata,
  input policy, escape policy, and manifest schema/version fields.
- A manifest reference document lists each field as checked, Lean-evidence,
  backend-witnessed, or informational.

Achievable:

- The Rust e2e harness already performs generic preflight over showcase and
  service artifacts.

Relevant:

- Leanix artifacts are where typed intent becomes something a user or agent can
  carry, inspect, replay, and trust without treating generated Nix as the source
  of truth.

Time-bound acceptance:

- By 2026-05-26, both artifact examples pass the generic verifier, and at least
  two negative manifest cases fail with exact stderr.

## Goal 3: Agent-Legible Graph Summary V1

Deadline: 2026-06-02.

Status: completed in `TICKET-0048`.

Specific:

- Add a machine-readable summary for one checked flake or registry example.
- The summary should expose systems, inputs, packages, apps, checks,
  formatters, source trust classes, policies, package edges, and raw escape
  hatches.
- Keep the summary derived from checked Leanix values, not from generated Nix.

Measurable:

- A command or Rust harness path emits the summary for at least one canonical
  example.
- The e2e harness verifies key fields in that summary.
- Documentation lists at least six questions an agent can answer from the
  summary without reading generated Nix.

Achievable:

- `ValidatedFlake`, `CheckedSystemOutputs`, manifest emission, and the example
  registry already contain most of the needed data.

Relevant:

- This is the first concrete step from "typed flakes" toward infrastructure an
  agent can inspect directly.

Time-bound acceptance:

- By 2026-06-02, `scripts/ci-local` passes and the summary is documented as a
  developer-facing experimental contract.

## Goal 4: Backend Contract V1

Deadline: 2026-06-09.

Specific:

- Document the supported generated-Nix subset as a backend contract.
- Strengthen the optional `nixparserlean` interop check around that contract,
  either through a dedicated summary mode or a stable, less-fragile JSON subset.
- Clearly separate Leanix graph correctness claims from Nix backend witness
  claims.

Measurable:

- The backend contract lists supported input forms, output families, defaults,
  build expression forms, and known unsupported Nix features.
- Optional interop covers the canonical artifact flake and at least three
  registry examples.
- Interop failures report whether the likely issue is Leanix output,
  contract drift, or sibling-checkout availability.

Achievable:

- The optional interop lane already parses/desugars/evals selected generated
  flakes and the artifact flake.

Relevant:

- Nix remains the active backend. Leanix must know the subset it emits and keep
  backend leakage visible.

Time-bound acceptance:

- By 2026-06-09, the standard e2e gate passes, and the optional
  `--nixparserlean-dir ../nixparserlean` gate verifies the documented contract
  when the sibling checkout is healthy.

## Goal 5: NixOS Control-Plane Design Spike

Deadline: 2026-06-09.

Specific:

- Write a design note for the first Leanix representation that points beyond
  flakes toward OS control.
- The note should model one tiny host/service relationship, such as a host
  profile, a service package, a port, a user, and a check, without claiming to
  replace NixOS modules.
- Identify which parts would lower to NixOS/Nix later and which parts should be
  reasoned about in Leanix.

Measurable:

- The design note includes one small typed sketch, a validation checklist, and
  a backend-lowering sketch.
- It names at least five agent questions that become answerable at the Leanix
  layer.
- It produces either one follow-up implementation ticket or an explicit decision
  not to implement yet.

Achievable:

- This is a design spike only; it should not attempt NixOS module generation in
  the first pass.

Relevant:

- The long-term vision is operating-system control, not only typed flake
  examples.

Time-bound acceptance:

- By 2026-06-09, the design note is committed and linked from the roadmap.
