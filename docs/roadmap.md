# Roadmap

## Phase 0: Vocabulary

- Define systems, source pins, hashes, inputs, packages, apps, shells, checks,
  and flakes.
- Keep the model pure. No subprocesses, no Nix store interaction.
- Add tiny example flakes as Lean values.

## Phase 1: Typed Output Schemas

- Distinguish conventional flake outputs by type.
- Add helpers for common output names like `default`.
- Define checks that every app points to an existing package and every output is
  available only on declared systems.

## Phase 2: Reproducibility Model

- Require hashes for fetch-like inputs.
- Track builder identity and declared dependencies.
- Model build plans separately from realized store paths.
- Add validation functions returning structured errors.

## Phase 3: Nix Interop

- Render a restricted Leanix graph to a `flake.nix`.
- Optionally read parsed Nix from `nixparserlean` for comparison.
- Check that rendered flakes preserve the typed output schema.

## Phase 4: Proofs

- Prove basic invariants about system compatibility.
- Prove graph closure properties for dependency traversal.
- Prove that validation success implies renderable output for the supported
  Nix backend subset.

