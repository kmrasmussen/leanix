# EnvVar End-to-End

Leanix now keeps `EnvVar` as real model surface instead of inert structure.

Packages can attach env vars to `runCommand` and `runSteps` builders, and the
renderer threads them into the generated `runCommand` attrset. Dev shells render
their env vars through `pkgs.mkShell { env = ...; }`. The new env example checks
that the package build actually sees `LEANIX_MESSAGE`, so the e2e path now
covers both rendering and Nix evaluation.

Validation owns the constraints before the graph reaches the renderer:
duplicate names are rejected within each package or dev shell, and package env
vars are only accepted on builders that have a surrounding command attrset where
Leanix can render them honestly.
