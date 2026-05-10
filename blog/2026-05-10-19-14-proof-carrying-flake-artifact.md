# Proof-Carrying Flake Artifact

Ticket 0007 gives Leanix its first artifact boundary.

`lake exe leanix emit-artifact --out generated/showcase-artifact` now writes a
directory with:

- `flake.nix`
- `leanix.manifest.json`

The manifest records the source reference, renderer version, generated files,
systems, input trust classes, packages, app/check references, checked invariant
names, and replay commands.

The important distinction is what each layer is allowed to claim:

- Lean carries typed graph and schema evidence: validated `CliProject`,
  checked package closure, finite acyclicity, and source trust checks.
- Rust owns artifact replay: filesystem shape, manifest inspection, checking
  declarations against the generated flake, and subprocess orchestration.
- Nix remains the witness that the rendered backend artifact evaluates and
  builds.

This is not a cryptographic proof object yet. It is the first durable home for
the claims Leanix makes and the replay steps that keep those claims honest.
