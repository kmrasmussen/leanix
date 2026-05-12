# Policy Matrix For CI And Impure Sources

`TICKET-0044` adds the first explicit policy matrix.

Leanix now distinguishes development, CI, and strict artifact contexts. The
development context remains ergonomic. CI is stricter and rejects explicitly
impure local sources plus raw escape hatches. Strict artifact policy is
strictest: it also rejects local development sources and floating flake inputs
without direct pin evidence.

This keeps the project honest about what can be trusted. Local development can
still use convenient sources and escape hatches, while CI and artifact paths can
reject weaker claims before Nix realizes the generated backend artifact.
