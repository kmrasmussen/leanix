# Structured Validation Errors

Ticket 0002 replaces stringly validation failures with typed Lean errors.

Graph validation now returns `ValidateError`, with distinct constructors for
missing package references, package cycles, missing input references, duplicate
names, and missing source hashes. `CliProject` schema validation now returns
`SchemaError` instead of raw strings.

The CLI still prints simple readable messages. The difference is that Rust e2e
can now assert exact expected failures for the invalid examples instead of only
checking that rendering failed.

This is a small but important pressure relief valve for the project. As the
model grows, tests should talk about error classes, not scrape whatever string
was convenient at the first prototype stage.
