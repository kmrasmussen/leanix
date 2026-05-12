# Generated Nix Backend Contract

Added a maintained contract for the Nix subset Leanix emits.

The new `docs/generated-nix-contract.md` separates Leanix graph claims from the
things Nix still witnesses: parsing, flake output evaluation, nixpkgs package
availability, and derivation evaluation/builds.

The contract records supported input forms, output families, synthetic defaults,
build expression forms, check command forms, interop coverage, generated-file
location, and non-goals.

The optional NixParserLean bridge now reports failures more precisely:
missing checkout, stale/broken sibling checkout, desugar/eval failure, and
parsed-contract mismatch. It remains optional and local-checkout based.
