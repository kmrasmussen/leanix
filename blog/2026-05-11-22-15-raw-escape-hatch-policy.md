# Raw Escape Hatch Policy

Leanix now has an explicit policy boundary for raw shell and raw build-script
escape hatches.

The development policy keeps the existing prototype workflow usable:
`CheckCommand.rawShell`, `BuildExpr.runCommand`, raw script installs, raw file
writes, and one-off build steps are still accepted for ordinary flake
validation. That matters because Leanix is still migrating examples from raw
strings toward typed build plans and typed check commands.

Proof-carrying artifacts now use strict artifact policy before emission. In that
context Leanix rejects raw check commands and the raw build-script forms that
hide behavior from validation. The showcase artifact moved its check to
`CheckCommand.packageExecutableToOutput`, so the main artifact still emits and
records `"escapePolicy": "strict-artifact"` in its manifest.

There is also a negative fixture, `leanix emit-raw-check-artifact --out DIR`,
that intentionally tries to emit an artifact with a raw shell check. The Rust
e2e harness asserts the exact strict-policy rejection. This is not a proof of
external command behavior, but it makes the artifact trust posture explicit and
keeps raw escape hatches from silently entering proof-carrying outputs.
