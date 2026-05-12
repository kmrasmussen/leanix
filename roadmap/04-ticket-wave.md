# Proposed Next Ticket Wave

This wave starts from the 2026-05-12 state: `TICKET-0034` through
`TICKET-0043` are effectively landed locally, `TICKET-0044` is the remaining
policy-layer slice, and `TICKET-0045`/`TICKET-0046` handled CI-regression
follow-up.

The next wave should advance the long-term vision directly:

```text
Leanix as a typed, agent-legible control plane over Nix
```

Each ticket should improve one of these properties:

- important relationships are represented in Leanix before backend lowering
- policy says when a claim is safe to trust
- artifacts carry evidence that Rust can verify or Lean can justify
- agents can inspect a checked graph without reading generated Nix
- Nix remains a backend witness, not the reasoning substrate

## TICKET-0044: Policy Matrix for CI and Impure Sources

Problem:

Leanix has development and strict artifact escape policies, plus input pin
policy, but there is no coherent matrix for CI and impure/local source rules.

Goal:

Define a small policy matrix for development, CI, and strict artifact contexts.

Scope:

- extend policy values or add a policy record for CI
- define behavior for floating flake refs, impure local sources, raw shell, and
  missing artifact evidence
- add e2e rejection cases for at least one CI-only or artifact-only rule
- keep development examples ergonomic
- update docs and manifests where policy is recorded

Acceptance:

- policy behavior is explicit in code and docs
- at least one impure/local source policy rejection has exact stderr coverage
- artifact manifests still record the active policy

## TICKET-0047: Artifact Manifest Contract Reference

Problem:

The manifest has become the carrier for artifact evidence, but its fields are
not yet documented as a stable contract.

Goal:

Document and test the artifact manifest as an evidence contract.

Scope:

- add a manifest schema/version reference document
- classify each manifest field as checked by Rust, backed by Lean evidence,
  witnessed by Nix, or informational
- make the Rust verifier reject missing or mismatched required fields
- add at least two exact stderr negative cases for malformed manifests

Acceptance:

- two artifact shapes still verify through the generic Rust path
- manifest schema/version fields are checked
- docs state what a verifier may trust and what remains informational

## TICKET-0048: Agent-Legible Graph Summary

Problem:

Leanix has checked graph data, but an agent still has to infer much of the
project shape from docs, manifests, or generated Nix.

Goal:

Emit a machine-readable summary derived from checked Leanix values.

Scope:

- expose systems, inputs, source trust classes, packages, package edges, apps,
  checks, formatters, policies, and raw escape hatches
- derive the summary before rendering Nix
- add e2e checks for a canonical registry example
- document concrete questions an agent can answer from the summary

Acceptance:

- at least one command or e2e path emits the summary
- e2e validates key summary fields
- docs list at least six agent questions answerable without reading generated
  Nix

## TICKET-0049: Escape-Hatch Inventory and Reduction Plan

Problem:

Raw escape hatches are explicitly named, but the project does not yet expose a
single inventory of where they appear and which policy contexts allow them.

Goal:

Make backend leakage inspectable and reduce one common raw path.

Scope:

- enumerate raw build, raw check, raw file/script, and raw flake escape hatches
- expose escape-hatch usage in artifact manifests or graph summaries
- replace one repeated raw usage with a typed constructor if a clear pattern
  exists
- document which policies allow or reject each class

Acceptance:

- strict artifact or CI policy can reject at least one escape-hatch class
- an agent-facing summary or manifest names the escape hatches in use
- one raw usage is either replaced or deliberately justified in docs

## TICKET-0050: Generated Nix Backend Contract

Problem:

Nix is the active backend, but the supported generated-Nix subset is spread
across renderer code, goldens, interop checks, and notes.

Goal:

Create a maintained backend contract for the Nix that Leanix emits.

Scope:

- document supported input forms, output families, defaults, build expression
  forms, source forms, and known unsupported Nix features
- connect representative contract points to goldens or parsed interop checks
- improve optional nixparserlean failure reporting if the sibling checkout is
  missing, stale, or contract-incompatible

Acceptance:

- docs separate Leanix graph claims from Nix backend witness claims
- optional interop covers the artifact flake and at least three registry
  examples
- generated files remain ephemeral under `generated/`

## TICKET-0051: NixOS Control-Plane Design Spike

Problem:

The long-term vision is OS control, but the current roadmap is still mostly
flake-shaped.

Goal:

Define the first tiny Leanix structure that points beyond flakes toward
NixOS-like control without attempting a NixOS replacement.

Scope:

- write a design note for one host/service relationship
- sketch typed fields such as host system, service package, port, user, check,
  source policy, and backend target
- define validation questions and agent questions before backend lowering
- identify the smallest future implementation ticket if the design is sound

Acceptance:

- design note includes one typed sketch and one backend-lowering sketch
- note states what remains delegated to NixOS/Nix
- follow-up ticket is created or explicitly deferred

## Wave Completion Criteria

The wave is complete when:

- the SMART goals in `roadmap/02-milestones.md` are either met or explicitly
  revised with dated rationale
- `scripts/ci-local` passes
- every completed ticket has a blog note and verification result
- the roadmap can answer: what can an agent now know from Leanix that it could
  not know before?
