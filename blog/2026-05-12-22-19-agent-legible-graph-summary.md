# Agent-Legible Graph Summary

Added the first machine-readable graph summary for checked Leanix values.

The new command is:

```bash
lake exe leanix summarize showcase --out generated/showcase-summary.json
```

The summary is emitted from `ValidatedFlake.checkedOutputs`, before Nix
rendering. It records active systems, inputs and trust classes, packages,
package edges, apps, dev shells, checks, formatters, policy descriptions,
carried invariant names, and raw escape hatches.

The Rust e2e harness now checks the showcase summary and a `hello` contrast
case. The showcase proves the normal typed path is visible to an agent, while
the `hello` summary proves raw shell checks are exposed instead of hidden inside
generated Nix.

This keeps the near-term shape aligned with the larger vision: generated Nix is
still the backend, but the graph an agent reasons about is becoming a checked
Leanix artifact.
