# Leanix Long-Term Vision

Leanix aims to be a typed control plane over Nix.

Nix embodies a large amount of working infrastructure: nixpkgs, flakes, the
store, builders, substituters, NixOS modules, and years of operational practice.
Leanix should not try to replace that in the near term. It should derive value
from it by making Nix the active backend while moving authoring and reasoning
into Lean.

The long-term goal is agent-legible infrastructure: build graphs, package
graphs, service graphs, policies, sources, machines, and eventually NixOS-like
configuration should be explicit structures that a proof assistant, compiler,
and software agent can inspect before any backend realization happens.

## The Problem

Today, a large system configuration is often a mixture of:

- dynamically shaped attribute sets
- stringly typed conventions
- shell fragments
- late failures during evaluation or build
- implicit relationships between packages, apps, checks, services, machines,
  users, secrets, caches, and sources
- backend-specific behavior that agents must infer by reading generated or
  handwritten Nix

This makes it hard for a strong agent to reason about the full structure of an
operating system. The agent can run commands, inspect files, and learn local
patterns, but the structure is not presented as a coherent typed object. Many
important questions require partial evaluation, backend knowledge, and
convention recovery.

Leanix exists to move those relationships into the foreground.

## The Desired World

In the desired end state, an agent controlling a machine should be able to ask
the Leanix layer questions such as:

- Which packages, services, checks, and machines depend on this input?
- Which sources are pinned, lockfile-backed, local-development only, or impure?
- Which parts of the graph can run raw shell?
- Which services can affect boot, networking, user sessions, or secrets?
- What changes if this source pin moves?
- Which packages are in the closure of this app?
- Does every app, check, formatter, and service point at a package for the same
  system?
- Which claims are backed by Lean evidence, which are backed by Rust
  verification, and which are delegated to Nix?

Most of those questions should be answerable from Leanix structures, without
spelunking through the generated Nix backend artifact.

## Relationship To Nix

Nix is the first backend and the practical realization layer.

Leanix values should lower to ordinary Nix artifacts because that is how the
system gets built, checked, cached, deployed, and integrated with existing
workflows. The generated Nix is important, but it is not the source of truth.

The source of truth is:

```text
Leanix value -> checked Leanix graph -> backend artifact -> Nix realization
```

Leanix should keep backend leakage explicit and exceptional. When a model uses
raw shell, a Nix-shaped builder, a local path, an impure source, a lockfile
witness, or a backend-specific convention, that boundary should be named in the
typed model and visible to policy checks.

## What Leanix Must Own

Leanix should own the authoring and reasoning layer:

- typed source and input declarations
- supported systems and system-indexed outputs
- package, app, dev shell, check, formatter, service, and machine relations
- build-plan intent before backend lowering
- validation boundaries that produce checked graph values
- policy contexts for development, CI, and strict artifacts
- proof-carrying or evidence-carrying artifacts
- queryable summaries that are easy for agents to consume

Nix should own the backend realization layer:

- actual derivation realization
- store paths
- nixpkgs integration
- binary caches and substituters
- NixOS integration while Leanix is still young
- final `nix build`, `nix flake check`, and deployment witnesses

Rust should own effectful tooling around the model:

- e2e harnesses
- subprocess orchestration
- filesystem crawling
- artifact verification
- lockfile and cache workflows
- operator commands that need OS effects

## Long-Term Bet

The bet is that Lean is a strong enough abstraction layer to make the important
relationships explicit and checkable before Nix sees the generated artifact.

Leanix does not need to model all of Nix first. It needs to grow a vertical
slice where the abstraction is strong enough that most reasoning happens above
the backend:

```text
typed intent
  -> checked graph evidence
  -> explicit policy
  -> generated Nix
  -> Nix backend witness
```

Each slice should be small enough to run, but ambitious enough to make an agent
less dependent on backend archaeology.

## Near-Term Consequence

The next roadmap should optimize for a narrow trusted subset, not broad Nix
coverage.

The project should first make a small set of schemas, build plans, policies,
artifacts, and interop checks precise enough that Leanix can say exactly what
it knows, what Rust verified, what Nix witnessed, and where reasoning becomes
weaker.

That is the path from "typed flakes" toward agent-legible operating-system
control.
