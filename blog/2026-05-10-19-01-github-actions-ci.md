# GitHub Actions CI

Ticket 0005 adds the first CI workflow for Leanix.

The workflow is intentionally small:

1. check out the repository
2. install Nix with flakes enabled
3. run `nix flake check`
4. run the Rust e2e harness through `nix develop`

The caching choice is also intentionally small. CI uses public Nix substituters
and does not publish or trust a project binary cache yet. That belongs after
Leanix has a clearer cache and provenance model.

This keeps CI aligned with the project boundary: Nix proves the root flake still
evaluates and builds, while Rust drives the generated-flake smoke tests.
