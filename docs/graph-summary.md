# Agent-Legible Graph Summary

`leanix summarize NAME --out generated/graph-summary.json` emits an
experimental JSON summary for a registered example. The summary is derived from
`ValidatedFlake.checkedOutputs`, before Nix rendering, so an agent can inspect
the checked Leanix graph instead of reverse-engineering generated `flake.nix`.

The current contract is intentionally small:

- `formatVersion`: summary schema version, currently `1`
- `summaryKind`: `experimental-graph-summary`
- `derivedFrom`: `checked-leanix-values`
- `escapePolicy`: the policy used for the checked graph, currently
  `development` for registry summaries
- `policies`: plain descriptions of the known policy levels
- `systems`: systems with at least one output family
- `inputs`: input names, source trust classes, pin policies, URLs, and pin
  evidence where present
- `packages`: package names, builder kinds, package dependency edges, and input
  dependency edges
- `apps`: app names, package targets, programs, and systems
- `devShells`: shell names and package targets
- `checks`: check names, package targets, command kinds, and command dependency
  edges
- `formatters`: formatter package targets
- `rawEscapeHatches`: raw build/check escapes that a stricter policy would
  reject
- `checkedInvariants`: invariant names carried by the checked value

## Example

```bash
lake exe leanix summarize showcase --out generated/showcase-summary.json
```

The showcase summary records that `helloWrapper` depends on `helloTool`, the
default app points at `helloWrapper`, the default check uses
`packageExecutableToOutput`, and the example has no raw escape hatches.

The `self` summary is useful as a negative contrast because its build check
still uses a raw shell command:

```bash
lake exe leanix summarize self --out generated/self-summary.json
```

## Agent Questions

An agent can answer these without reading generated Nix:

- Which systems have outputs?
- Which inputs are floating, pinned, fixed-output, local development, or impure
  local sources?
- Which package depends on a given package?
- Which apps point at a package?
- Which checks point at a package, and do their commands use typed command
  forms?
- Which dev shells include a package?
- Is a formatter configured, and which package backs it?
- Which raw escape hatches would block a CI or strict artifact policy?
- Which invariant names came through the checked boundary?

## Boundary

This summary is not a semantic equivalence proof for Nix evaluation. It is an
agent-facing view of the Leanix graph after Leanix validation and before backend
rendering. Downstream tooling should treat `formatVersion` and `summaryKind` as
the compatibility boundary while the contract is still experimental.
