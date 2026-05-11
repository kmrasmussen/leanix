# CLI Example Registry

Leanix now has a small CLI registry for renderable examples.

The old specific commands remain in place: `render-cli-schema`,
`render-showcase`, `render-multi-system-schema`, and the rest still work and
still back the existing e2e fixtures. The new path is discoverable:
`leanix list-examples` prints the registry names, and
`leanix render NAME --out generated/flake.nix` renders one of them.

The registry intentionally stays explicit. It includes the current renderable
examples, including schema examples, backend/escaping examples, source fixture
examples with default local sources, and the self flake with a local `path:.`
source. Unknown names fail with a short exact error.

The Rust e2e harness now covers the registry path by listing examples, rendering
`hello` through the generic command, comparing it to the existing golden, and
checking the unknown-example error. This improves exploration without removing
the stable command spellings that tests and existing notes already use.
