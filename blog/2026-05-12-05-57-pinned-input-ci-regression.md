# Pinned Input CI Regression

GitHub Actions caught a real compatibility issue in the pinned input fixture.

Leanix rendered a GitHub input with both `ref = "nixos-unstable"` and a concrete
`rev`. Current Nix rejects that combination because the input contains both a
branch/tag name and a commit hash.

The renderer now keeps the concrete pin as the source of truth: when `rev` is
present, it emits `rev` and `narHash` but omits the URL-derived `ref`. The
pinned-input golden and proof-carrying artifact fixture were regenerated to
match.

This also produced two follow-up tickets: the immediate renderer regression
ticket, and a local CI parity ticket so the same checks are easy to run before
push.
