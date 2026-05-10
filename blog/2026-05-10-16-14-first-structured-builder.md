# First Structured Builder

Leanix now has a first structured build-step layer.

`BuildStep` currently supports:

- `mkdir`
- `writeFile`
- `chmodExecutable`
- raw `run`

`BuildExpr.runSteps` renders those steps through the Nix backend as a
`runCommand` script. The closure example now builds `helloWrapper` with
structured steps instead of one raw shell string.

This does not complete structured builders yet. The self-build still uses a raw
script, and checks still carry shell command strings. But the direction is now
concrete: build behavior can move into typed Lean data one operation at a time.
