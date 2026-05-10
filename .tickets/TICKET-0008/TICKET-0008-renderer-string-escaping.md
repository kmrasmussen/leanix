# TICKET-0008: Renderer String Escaping

## Problem
`Leanix/Render.lean::renderString` is `"\"" ++ value ++ "\""`. Nothing else in
the renderer escapes embedded text either: package names, app `program`, source
URLs from `--source`, dev-shell entries, and check command bodies all flow into
generated Nix as raw concatenation.

Two failure modes follow:

1. Any `"`, `\`, newline, or control character in a Lean string produces broken
   Nix. The break only surfaces at `nix flake check`, not at validation.
2. User-controlled input becomes a Nix injection vector. The clearest
   reproduction is:
   ```sh
   lake exe leanix render-self --source 'path:/x";\nbad="' --out generated/flake.nix
   ```
   which closes the `nixpkgs.url = "..."` literal and injects new attrset
   entries.

The same issue affects the `''…''` script literals emitted by
`BuildExpr.runCommand` / `BuildExpr.runSteps` (any embedded `''` terminates the
literal) and the `<<'EOF'` heredoc body emitted by `BuildStep.writeFile` (any
line equal to `EOF` terminates the heredoc).

## Goal
Make the renderer produce valid Nix for every `Flake` value that passes
`validateFlake`, regardless of input string content.

## In Scope
- A single Nix-string escaping helper used by every `renderString` call site.
- A `''…''` escaping strategy for embedded scripts (Nix's escape sequence is
  `'''` for a literal `''`).
- A heredoc-safe rendering strategy for `BuildStep.writeFile` content. Either
  pick a non-collidable delimiter, escape, or stop using a shell heredoc.
- Tests in the Rust e2e harness that feed strings containing `"`, `\`, `''`,
  and `EOF` through every renderer code path.
- Documenting any remaining cases where invalid characters are rejected at
  validation time instead of escaped at render time.

## Out of Scope
- Restructuring `BuildStep` further (TICKET-0012 is the typed-reference path).
- Locking down `--source` argument shape beyond what escaping requires.
- Nix string interpolation `${…}` semantics beyond escaping the `$` and `{`
  characters when they appear unintentionally.

## Acceptance Criteria
1. Every renderer call that produces a Nix string literal goes through one
   escaping helper.
2. The Rust e2e harness contains at least one positive case whose package or
   input names include `"`, `\`, and `''`, and the rendered flake passes
   `nix flake check`.
3. The Rust e2e harness contains at least one positive case whose
   `BuildStep.writeFile` content contains both a literal `''` and a line
   equal to `EOF`.
4. `lake exe leanix render-self --source 'path:/x";a="b'` either escapes the
   value safely or rejects it; it never produces a flake whose `inputs`
   attrset contains attributes the user did not declare.

## First Slice
1. Add `Leanix.Render.escapeNixString : String -> String`.
2. Replace `renderString` body and audit call sites.
3. Add one Rust e2e case with a quote-bearing package name.

The `''…''` and heredoc cases can be a separate follow-up commit, but the
escaped-string helper should land first and gate the others.

## Progress
- Added `escapeNixString` and routed `renderString` through it.
- Render package/app/shell/check names as quoted Nix attribute names.
- Escaped raw indented scripts for `''` and `${`.
- Replaced heredoc-based `writeFile` rendering with `pkgs.writeText`.
- Added a positive Rust e2e case with `"`, `\`, `''`, and `EOF` content.
- Added a source-argument injection regression check for `render-self`.
