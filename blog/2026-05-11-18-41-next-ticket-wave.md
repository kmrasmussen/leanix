# Next Ticket Wave

Added `TICKET-0016` through `TICKET-0025` as the next Leanix backlog wave.

The previous fifteen tickets completed the first PoC: typed graph values,
validated render boundaries, source trust modeling, structured builders,
golden/e2e checks, proof-carrying artifacts, and a local nixparserlean smoke
lane.

The new tickets move the pressure outward:

- make nixparserlean interop part of the Rust-owned verification story
- compare parsed generated Nix back to Leanix's typed output claims
- grow schemas beyond one-system `CliProject`
- split typed build plans from Nix backend expressions
- make builder identity, lockfile policy, artifact replay, closure proofs, and
  typed checks more load-bearing

This keeps the project moving toward typed-first flakes without pretending the
PoC already proves Nix evaluation or covers the whole flake surface.
