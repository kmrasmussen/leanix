# Typed Build Text

The showcase wrapper no longer embeds a raw Nix package interpolation inside a
Lean string.

`BuildText` now gives build steps a small typed text language: literals,
package references, input-path references, output-path references, and
concatenation. The renderer lowers those fragments into Nix strings, while the
validator walks the same fragments for package and input references. That means
a script can say "use package `helloTool`" as Lean data instead of smuggling
`${self.packages.${system}.helloTool}` through text.

Raw text constructors still exist as migration escape hatches, and the PoC
docs now name them explicitly. The important change is that the canonical
proof-carrying showcase uses the typed path, and e2e now rejects a missing
package reference hidden inside typed build text.
