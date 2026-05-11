# BuildPlan File Constructors

Leanix now has more of the everyday file work in `BuildPlan` instead of only in
backend-shaped `BuildStep` values.

This slice adds two named plan constructors:

- `BuildPlan.copyInputFile`, for copying one file out of a declared source
  input into a package output
- `BuildPlan.installTextFile`, for installing typed text content into a package
  output

The important boundary is not that the generated Nix became clever. It did not.
Both plans still lower to the existing structured `runSteps` backend. The win is
that input and package references are visible at the plan layer, before the
backend expression is chosen.

The existing hashed source fixture now uses `BuildPlan.copyInputFile` instead of
directly authoring `BuildExpr.runSteps`. A new text-file example pins
`BuildPlan.installTextFile` with a golden fixture. The invalid e2e case checks a
missing source input reference before rendering, with exact stderr.

This keeps the model small: common file operations become semantic plan nodes,
while the Nix renderer remains a backend detail.
