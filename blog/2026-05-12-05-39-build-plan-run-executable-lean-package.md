# BuildPlan Run Executable And Lean Package

`BuildPlan` now has two more named package-authoring identities.

`BuildPlan.runPackageExecutableToOutput` runs an executable from a referenced
package and writes stdout to `$out`. The example package `helloVersion` uses it
to run `hello --version`, and the Rust e2e harness builds that package and
checks the generated output.

`BuildPlan.leanPackageFromInputTree` copies an input tree, runs `lake build`,
and touches `$out`. The self-check package now uses this plan instead of
hand-authored `BuildExpr.runSteps`, which makes the `leanixSrc` input reference
visible at the plan layer before lowering.

The constructors still lower to the existing `BuildExpr.runSteps` backend. That
is intentional for this slice: the important step is naming the authoring
intent and validating package/input references before backend rendering.
