# Renderer String Escaping

Ticket 0008 closes the most obvious renderer injection hole.

Nix string literals now go through `escapeNixString`, attribute names are
rendered as quoted Nix attributes, and raw indented script bodies escape Nix's
`''` terminator. `BuildStep.writeFile` and `installExecutableScript` no longer
emit shell heredocs; they use `pkgs.writeText`, which means a line equal to
`EOF` is no longer special.

The e2e harness now includes a positive escaping flake whose package/check names
contain `"`, `\`, and `''`, and whose `writeFile` content contains both `''`
and an `EOF` line. It also checks that a hostile `render-self --source` value
does not inject a new input attribute into the generated flake.

One design choice remains explicit: executable script content may still contain
intentional Nix interpolation. Leanix uses that for wrapper scripts that bake in
typed package references. Ordinary string values, including user-provided
source URLs, do not get that privilege.
