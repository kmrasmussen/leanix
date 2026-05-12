# Policy Matrix

Leanix uses policy contexts to separate ergonomic development from stronger
claims that can be trusted in CI or proof-carrying artifacts.

The policy value is currently named `EscapePolicy` because it started as raw
escape-hatch validation. It now also controls source/input policy.

## Policy Contexts

| Input or escape class | Development | CI | Strict artifact |
| --- | --- | --- | --- |
| Floating flake input | allowed | allowed in V1 | rejected unless `rev` and `narHash` are present |
| Pinned flake input with `rev` and `narHash` | allowed | allowed | allowed |
| Fixed-output source with `narHash` | allowed | allowed | allowed |
| Fixed-output source without `narHash` | rejected | rejected | rejected |
| Local development source | allowed | allowed in V1 | rejected |
| Impure local source | allowed | rejected | rejected |
| Raw build command or raw build step | allowed | rejected | rejected |
| Raw check command | allowed | rejected | rejected |
| Typed build/check constructors | allowed | allowed | allowed |

## Claims

Development policy is for iteration. It keeps local sources, floating refs, and
raw escape hatches available so examples remain easy to write.

CI policy is a narrow validation mode for work that should not depend on
explicitly impure local sources or raw shell escape hatches. It still allows
floating flake inputs in V1 because the current development and e2e workflow
lets Nix create lockfile witnesses during checks.

Strict artifact policy is for proof-carrying artifact emission. It rejects raw
build/check escape hatches, explicitly impure or development-local sources, and
floating flake inputs that lack direct pin evidence. Artifact manifests still
record the active policy as `escapePolicy`.

These policies do not prove Nix evaluation correctness. They define which
Leanix-authored claims are strong enough to carry into CI or artifacts before
Nix acts as the backend witness.
