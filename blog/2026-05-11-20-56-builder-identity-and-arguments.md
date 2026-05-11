# Builder Identity and Arguments

The build-plan layer now carries typed builder identity instead of only
string-shaped backend expressions.

`BuildPlan.nixpkgsPackage` takes a `KnownNixpkgsPackage`, so a package can say
it wants the known `hello` package without writing the raw nixpkgs attr path at
the authoring boundary. `BuildPlan.executableTextWrapper` and
`BuildPlan.copyInputTree` now take named argument records, which makes the
builder contract easier to inspect before lowering to Nix.

The renderer still sees `BuildExpr`. That is intentional for this slice: the new
typed contract lowers to the same backend representation, and the existing
closure/showcase golden checks prove the generated flakes stayed stable.

Validation now inspects one argument invariant directly on plans. Duplicate
wrapper arguments fail before rendering, alongside the missing package-reference
case from the previous build-plan slice. This is not a full builder language
yet, but it gives Leanix a concrete place to grow builder-specific checks.
