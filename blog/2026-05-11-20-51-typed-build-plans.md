# Typed Build Plans

Leanix now has a first build-plan layer in front of the Nix-shaped backend
expression.

`BuildExpr` is still the renderer input. That keeps this slice small and keeps
the existing generated flakes stable. The new `BuildPlan` type sits one step
earlier: it describes common package intentions, exposes package and input
references for validation, and then lowers to `BuildExpr`.

The first plans cover three small cases: using a package from nixpkgs, building
an executable text wrapper around another package, and copying an input tree.
The closure example now authors `helloWrapper` as `helloWrapperPlan` and lowers
it with `Package.fromBuildPlan`, so the existing closure/showcase golden files
continue to pin the same generated Nix.

The e2e harness also has a negative build-plan case. It validates a wrapper plan
that references a missing package and expects the failure before rendering. That
is the boundary this ticket needed: Leanix can inspect plan dependencies before
choosing the concrete backend expression.
