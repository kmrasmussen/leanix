# Lockfile Witness Metadata

Artifact input policy now distinguishes directly pinned flake inputs from
lockfile-backed flake inputs.

The manifest model has new optional witness fields on `ArtifactInput`:

- `lockfile`
- `lockfileNode`
- `lockedRev`
- `lockedNarHash`

The verifier still rejects plain floating flake inputs. It now also accepts the
separate `lockfile-backed-flake-input` trust class when those witness fields are
present, and rejects that trust class when the witness is missing.

This is deliberately metadata verification, not lockfile resolution. Leanix does
not run `nix flake lock`, fetch inputs, or prove that a lockfile node matches a
remote source. The artifact boundary records evidence and checks that the
claimed evidence exists.

The e2e harness covers three policy paths now:

- directly pinned input metadata verifies
- unsupported floating input metadata fails
- lockfile-backed input metadata verifies only when witness fields are present
