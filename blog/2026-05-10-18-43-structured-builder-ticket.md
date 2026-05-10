# Structured Builder Ticket

Ticket 0001 is now closed.

The important shift is that the self-check flake no longer hides its source
copy and Lean build inside one opaque shell string. It now says, as Lean data:

- copy the `leanixSrc` input into `source`
- build the Lean project in `source`
- run the remaining small command to create `$out`

The wrapper examples also moved from a sequence of shell-shaped filesystem
steps to one semantic operation: install this executable script.

This is still intentionally modest. Leanix does not model every Nix builder,
and checks still use command strings. But the direction is better aligned with
the project: keep common build intent visible in Lean, leave Nix as the backend,
and make raw shell the explicit exception instead of the default authoring
surface.
