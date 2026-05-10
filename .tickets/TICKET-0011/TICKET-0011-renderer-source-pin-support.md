# TICKET-0011: Renderer Source Pin Support

## Problem
`SourcePin` carries `url`, `rev?`, and `narHash?`, but the renderer ignores
all but `url`:

```lean
| .flake pin => pure s!"    {input.fst}.url = {renderString pin.url};"
```

A Lean value that *looks* pinned (carries a `rev` and a `narHash`) is silently
rendered unpinned. That is the opposite of what the typed flake model
promises.

The same area has another asymmetry: `validateInput` requires every
`Input.source` to carry a `narHash`, but `renderInputLine` rejects
`Input.source` outright with "the renderer does not support hashed source
inputs yet". So the validated invariant cannot be reached from any rendered
flake; only `flake` and `localSource` ever make it to Nix.

This ticket complements `TICKET-0006` (typed source trust model). 0006 is
about the model side; this ticket is about making the renderer faithful to
whatever the model expresses.

## Goal
Make rendered flakes preserve the pinning information the typed flake claims
to carry.

## In Scope
- Render `SourcePin.rev?` and `SourcePin.narHash?` for `Input.flake` inputs
  (e.g. `<name>.url`, `<name>.rev`, `<name>.narHash` attrset shape, or the
  url-with-`?rev=` shorthand — pick one and document it).
- Render `Input.source` inputs as fixed-output flake `inputs` entries (or
  reject them with a structured error rather than the current freeform
  string).
- Tests in the Rust e2e harness covering a pinned `flake` input and a
  hashed `source` input round-tripping through `nix flake check`.

## Out of Scope
- Generating or consuming `flake.lock` files.
- Resolving rev/narHash automatically from a remote URL.
- Source trust classification beyond what `Input` already distinguishes
  (`TICKET-0006`).

## Acceptance Criteria
1. A `Flake` whose `nixpkgs` input carries `rev?` and `narHash?` produces a
   rendered flake that records both, and `nix flake check` accepts it.
2. A `Flake` whose `Input.source` carries a `narHash` either renders to a
   working pinned source input or fails validation/rendering with a clear
   structured error — not the current "renderer does not support" string.
3. Rust e2e covers at least one pinned-flake-input case and one hashed-source
   case (positive or negative as fits the chosen design).

## Notes
- Decide whether pin metadata is mandatory at validation time, optional but
  rendered when present, or both (`flake` inputs may have an unpinned form
  for `nixos-unstable`-style references; `source` inputs should not).
- Coordinate with `TICKET-0006` so the model side and renderer side land
  consistent shapes.
