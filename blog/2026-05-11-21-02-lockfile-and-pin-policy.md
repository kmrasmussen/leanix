# Lockfile and Pin Policy

Leanix now distinguishes development input ergonomics from proof-carrying
artifact input claims.

Development flakes can still use floating refs. That keeps the normal local loop
pleasant: render a flake, let Nix resolve it, and let `flake.lock` move as part
of ordinary development.

Proof-carrying artifacts now need evidence. The showcase artifact uses a pinned
nixpkgs input, and its manifest records the input trust class, pin policy,
revision, and hash. The manifest no longer calls a floating ref
"lockfile-backed" unless it has evidence to justify that claim.

`verify-artifact` rejects floating flake inputs in an artifact manifest unless a
future lockfile witness is recorded. The Rust e2e harness mutates a generated
artifact into that invalid policy shape and checks the verifier failure. That
gives Leanix a first concrete boundary: floating refs are fine for development,
but proof-carrying artifacts must carry pins or lockfile evidence.
