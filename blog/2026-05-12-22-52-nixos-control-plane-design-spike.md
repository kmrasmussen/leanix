# NixOS Control-Plane Design Spike

Added the first design note for a Leanix shape that points beyond flakes toward
OS control.

The sketch models one host/service relationship:

```text
Host -> Service -> Package -> Check
```

It names typed fields for host system, service package, port, user, check,
source policy, and backend target. It also separates the Leanix reasoning layer
from what remains delegated to NixOS and Nix.

Implementation is explicitly deferred. The next plausible slice is a
`HostService V1` that validates host/service/package/check relationships,
emits an agent-legible host summary, and lowers only to an existing flake
app/check target.
