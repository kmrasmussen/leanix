# BuildPlan Path Validation

Build-plan argument records now get a small authoring-time path check before
they lower to `BuildExpr`.

The rules are intentionally simple: paths cannot be empty, cannot contain `..`
segments, and cannot be absolute host paths. Output destinations are stricter:
they must be `$out` or live under `$out/`.

This is not a filesystem security model. It is a guardrail for the typed
authoring layer, catching mistakes like copying `../secret.txt` from an input
tree or installing a generated file to `/tmp/message.txt` before those mistakes
turn into generated Nix or build-time failures.
