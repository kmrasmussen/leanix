# TICKET-0025: Typed Checks and Shell Escape Reduction

## Problem
Leanix now has typed build text and structured build steps, but several
important surfaces are still raw shell or raw text:

- `Check.command`
- `BuildExpr.runCommand`
- `BuildStep.run`
- raw `installExecutableScript`
- raw `writeFile`

Those escape hatches are explicit, but common workflows still depend on them.

## Goal
Reduce raw shell reliance by adding typed check and command forms for the
common cases Leanix should understand.

## In Scope
- A typed check command representation that can reference packages, inputs, and
  output paths without raw interpolation.
- Structured command steps for common operations such as running a package
  executable, writing output, checking files, and composing simple commands.
- Validation that package/input references inside typed checks resolve.
- Migrate at least one existing check and one build step away from raw shell.
- Keep raw shell as an explicit unsafe or escape-hatch constructor.

## Out of Scope
- Building a full shell language in Lean.
- Removing all raw shell support.
- Proving command execution semantics.

## Acceptance Criteria
1. At least one `Check` no longer stores its behavior as a plain command
   string.
2. Missing package/input references inside typed checks fail validation.
3. Generated Nix remains readable and passes the Rust e2e harness.
4. Docs list the remaining raw escape hatches and when they are acceptable.

## Plan
- Add `CheckCommand` with typed constructors and keep raw shell as an explicit
  escape hatch.
- Validate package/input references mentioned inside typed check commands.
- Add one structured build step for a common raw-shell copy operation and
  migrate an existing example to it.
- Migrate one existing check to typed command authoring.
- Add invalid e2e coverage, docs, and a dated blog note.

## Progress
- Added `CheckCommand` with raw shell, package executable, and input path typed
  forms.
- Added validation for package/input references inside typed check commands.
- Migrated `closureCheck` to `CheckCommand.packageExecutableToOutput`.
- Added `BuildStep.copyFile` and migrated the source fixture copy away from
  raw `BuildStep.run`.
- Added an invalid typed-check e2e case for a missing package reference.
- Updated docs and added a dated blog note.
- Verification:
  - `nix develop --command lake build`
  - `nix develop --command cargo run --locked --manifest-path e2e/runner/Cargo.toml`
