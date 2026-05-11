# Typed Checks and Shell Escape Reduction

Checks now have a typed command surface.

`CheckCommand.rawShell` remains available for cases Leanix does not understand
yet, but checks can now use typed commands for common paths. The first typed
forms run a package executable into `$out` and assert that an input path exists.
Validation walks those typed command references, so a missing package inside a
check command fails before rendering.

The closure check moved from a raw command string to
`CheckCommand.packageExecutableToOutput`, and the source fixture build replaced a
raw copy command with the structured `BuildStep.copyFile` step. Generated Nix is
still intentionally simple and readable.

This does not remove shell as an escape hatch. It makes the common path more
explicit, while leaving raw command text visible where Leanix has not modeled the
operation yet.
