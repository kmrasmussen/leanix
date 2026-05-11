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
