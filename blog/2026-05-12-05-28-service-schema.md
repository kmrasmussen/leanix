# Service Schema

`ServiceProject` adds the first daemon-style schema to the typed authoring
surface.

The shape stays deliberately small: one main package, optional supporting
packages, a default app that points at the main package, a default development
shell, and one or more checks that also point at the main service package. This
is enough to model a common flake pattern without pretending to model process
supervision, ports, sockets, or runtime service policy.

The valid example lowers through `ValidatedSchema` before it becomes a
`ValidatedFlake`, so the renderer still consumes a checked boundary. The e2e
harness now golden-compares `render-service-schema`, runs `nix flake check` on
the generated flake, and checks an exact stderr path for a broken service
health check reference.

The docs also now say where the schema stops. Use `ServiceProject` when the
important convention is package/app/check wiring for one daemon-like command.
Use raw `Flake` and `Outputs` when the shape needs runtime policy or service
manager semantics Leanix has not modeled yet.
