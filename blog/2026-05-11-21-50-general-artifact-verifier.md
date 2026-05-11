# General Artifact Verifier Skeleton

`leanix verify-artifact` now has a generic manifest preflight before the
showcase-specific checks.

The manifest records a `fileHashes` section alongside `generatedFiles`. The
verifier reads those manifest fields, checks that each declared generated file
exists, and verifies the recorded content hash for files listed in
`fileHashes`. A tampered `flake.nix` now fails before replay commands run. A
missing generated `flake.nix` also fails at the manifest boundary.

This is still a skeleton, not a public artifact format. The hash is a
Leanix-local content hash for tamper detection, not a signature or remote cache
integrity story. The value of this slice is the new shape: manifest claims are
starting to become verifier inputs instead of comments beside a
showcase-specific string check.

The Rust e2e harness now covers:

- the generated showcase artifact
- the committed showcase artifact
- tampered generated `flake.nix` rejection
- missing generated file rejection
- existing floating-input policy rejection

The remaining showcase checks are intentionally kept in place while the generic
verifier grows around them.
