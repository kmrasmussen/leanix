# TICKET-0012: Typed References in Build Steps

## Problem
`BuildStep` is structured (mkdir, writeFile, chmodExecutable, raw run) but
`BuildStep.writeFile` takes a plain `String` for content. The current
showcase uses that escape hatch to embed a Nix interpolation directly:

```lean
.writeFile "$out/bin/hello-wrapper" (
  "#!/bin/sh\n" ++
  "${self.packages.${system}.helloTool}/bin/hello --version"
)
```

That `${self.packages.${system}.helloTool}` is a Nix interpolation living
inside a Lean string. Leanix already has a typed reference for this:
`BuildExpr.package`. The structured builder layer quietly bypasses it. The
"build behavior moves into typed Lean data" framing in
`blog/2026-05-10-16-14-first-structured-builder.md` and the showcase pitch
overstate this until typed references work inside `BuildStep`.

## Goal
Let `BuildStep` reference packages, inputs, and store paths through typed
nodes the renderer interpolates, so authors don't reach back into raw Nix
strings to express dependencies.

## In Scope
- A typed string-fragment representation for `BuildStep` content (e.g. a
  `BuildText` ADT with `literal`, `package`, `input`, and `outPath` cases).
- Renderer support that lowers each fragment to the appropriate Nix
  interpolation form.
- Validator support that treats package-references inside `BuildStep` the
  same way it treats `BuildExpr.package` (must resolve, must be acyclic).
- Migrate the showcase wrapper's `writeFile` content to typed fragments.
- Document the remaining raw escape hatches (e.g. `BuildStep.run` is still
  a shell command body) and what justifies keeping them.

## Out of Scope
- Replacing every shell command with typed steps (TICKET-0001 owns the
  broader builder direction).
- Modeling string-vs-path distinctions in Nix beyond what is needed for
  package interpolation.

## Acceptance Criteria
1. The showcase no longer contains a raw `${self.packages.${system}.X}`
   inside a Lean string literal; the dependency is expressed via a typed
   fragment.
2. Validation rejects a typed fragment that references a missing package,
   reusing the same code path as `BuildExpr.package`.
3. The Rust e2e harness still passes, including the golden showcase
   comparison after the expected file is regenerated.

## First Slice
1. Add `BuildText` ADT and a fragment-based variant of `BuildStep.writeFile`,
   keeping the raw form available behind a clearly named "raw" constructor
   for transition.
2. Migrate the showcase wrapper.
3. Tighten validation to walk fragments for package references.
