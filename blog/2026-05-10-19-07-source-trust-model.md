# Source Trust Model

Ticket 0006 makes the first source trust boundary explicit.

Leanix now distinguishes:

- lockfile-backed flake inputs (`Input.flake`)
- fixed-output fetched sources (`Input.source`)
- local development sources (`Input.localDevSource`)
- explicitly impure local sources (`Input.impureLocalSource`)

The important behavioral change is that fixed-output sources are no longer a
dead branch of the model. If they carry a `narHash`, the renderer lowers them to
a `builtins.fetchTree` binding. If they do not carry a hash, validation fails
before rendering.

Local sources are still supported for the self-check workflow, but the type and
rendered output now say what they are: development-only or impure inputs, not
reproducible source pins.
