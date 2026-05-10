# TICKET-0015: EnvVar End-to-End

## Problem
`Package` and `DevShell` carry `env : List EnvVar`, where `EnvVar` is a
`{ name : String, value : String }` record. No validator inspects the field,
no renderer path reads it, and no example sets it to a non-empty list. The
field is dead structure.

This is the kind of empty modeling that pretends a typed flake covers more
ground than it does. Either remove it until the renderer is ready, or wire
it through both validation and rendering so it earns its place in the model.

## Goal
Decide whether `EnvVar` is part of the typed flake model now or later, and
make the code reflect that decision.

## In Scope
- One of:
  - **Remove**: drop `env` from `Package` and `DevShell` until a concrete
    use case lands; update examples accordingly.
  - **Wire through**: render `Package.env` as the `env` attrset in the
    surrounding `runCommand`, render `DevShell.env` as `mkShell { env = … }`
    or via `shellHook` exports, validate that names are unique within a
    package/shell, and add at least one example exercising it.
- Whichever route, document the choice in a short blog entry (per
  `AGENTS.md`'s "Write design notes when introducing major concepts").

## Out of Scope
- Modeling Nix `passAsFile`, secret environments, or sandbox-controlled env
  variables.
- Cross-system env differences.

## Acceptance Criteria
1. The model state of `EnvVar` matches what the renderer and validator
   actually do — either it's gone, or it's exercised end-to-end.
2. If kept: at least one example sets a non-empty `env`, the rendered Nix
   includes those variables, and `nix flake check` succeeds.
3. If kept: validation rejects duplicate env names within a single
   `Package` or `DevShell`.

## Notes
Removing first and adding back later is acceptable; the goal is to stop the
"looks like Leanix models environment variables" misread of the current code.
