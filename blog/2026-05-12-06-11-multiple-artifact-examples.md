# Multiple Artifact Examples

Leanix now emits a second proof-carrying artifact shape:

```sh
lake exe leanix emit-service-artifact --out generated/service-artifact
```

The original showcase artifact still exercises the `CliProject` closure path.
The new service artifact comes from `ServiceProject`, records the `health`
check, and carries `ServiceProject.*` invariant names in the manifest.

The Rust e2e harness verifies both artifact directories with the same generic
preflight. That keeps generic artifact verification from silently depending on
the CLI showcase contract.
