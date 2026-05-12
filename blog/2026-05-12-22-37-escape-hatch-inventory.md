# Escape Hatch Inventory

Documented the current escape-hatch surface and removed one repeated raw shell
pattern.

The shared `helloCheck` now uses `CheckCommand.packageExecutableToOutput`
instead of `CheckCommand.rawShell`. That moves the ordinary hello-family
examples onto a typed command form while keeping rendered output equivalent.

Raw behavior is still intentionally covered. `rawHelloCheck` remains as the
fixture for strict artifact rejection, and the graph-summary e2e case now uses
the `self` example to prove `rawEscapeHatches` names raw shell usage for an
agent.

The new `docs/escape-hatches.md` file classifies raw checks, raw derivation
builders, raw build steps, raw file/script writes, and raw `Flake` authoring by
policy context.
