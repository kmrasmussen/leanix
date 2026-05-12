# Artifact Manifest Contract

`TICKET-0047` turns the artifact manifest into a more explicit contract.

The manifest now has documented schema fields, `formatVersion` and
`rendererVersion`, and the Rust verifier checks them before trusting the rest
of the artifact. The verifier also has negative cases for a missing schema field
and an unsupported schema version.

The new reference document classifies manifest fields by trust boundary: what
Rust checks directly, what comes from Lean evidence, what Nix witnesses during
replay, and what remains informational.
