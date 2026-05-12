# NixOS Control-Plane Sketch

Leanix should point beyond flakes without pretending to replace NixOS modules in
the near term. The first plausible step is a tiny host/service relationship
that an agent can inspect before backend lowering.

## Scope

This sketch models one service running on one host:

```text
Host -> Service -> Package -> Check
```

The goal is not deployment. The goal is to make the relationship explicit
enough that an agent can reason about it in Leanix before NixOS or Nix does the
real system construction.

## Typed Sketch

```lean
structure HostService (system : System) where
  name : String
  packageName : String
  port : Nat
  user : String
  checkName : String

structure HostConfig where
  hostName : String
  system : System
  services : List (HostService system)
  backendTarget : BackendTarget
  sourcePolicy : EscapePolicy

inductive BackendTarget where
  | flakeApp
  | nixosModule
  | nixosConfiguration
```

The package and check names would refer to already checked Leanix package and
check outputs for the same system. `backendTarget` is intentionally explicit so
an agent can tell whether this is still only a flake-level app/check, a future
NixOS module fragment, or a full `nixosConfigurations` target.

## Validation Questions

Before backend lowering, Leanix should be able to ask:

- Does every service package reference an existing package for the host system?
- Does every service check reference an existing check for the host system?
- Does every service port fall in an allowed range?
- Are service names unique per host?
- Are service ports unique per host unless sharing is explicitly modeled?
- Is the service user non-empty and free of obvious shell/path metacharacters?
- Is the host source policy strong enough for the selected backend target?

These are intentionally executable checks first. Proof obligations can grow
after the shape proves useful.

## Agent Questions

An agent should be able to answer these at the Leanix layer without reading
generated Nix:

- Which services run on this host?
- Which package backs a service?
- Which check proves a service is present or healthy?
- Which services expose ports, and are there conflicts?
- Which system is the host targeting?
- Which backend target will realize the host/service relationship?
- Which inputs or escape hatches affect the service package?
- Would CI or strict artifact policy reject this host graph?

## Backend-Lowering Sketch

The first implementation should not generate NixOS modules immediately. A safe
lowering ladder is:

1. `BackendTarget.flakeApp`: lower the service to an app/check pair inside the
   existing flake backend.
2. `BackendTarget.nixosModule`: later emit a small module fragment with
   `systemd.services.<name>`, `users.users.<user>`, and package references.
3. `BackendTarget.nixosConfiguration`: later assemble a complete
   `nixosConfigurations.<hostName>` from typed host records and module
   fragments.

A rough future NixOS module shape could be:

```nix
{ pkgs, ... }: {
  users.users.leanix-service = {
    isSystemUser = true;
    group = "leanix-service";
  };

  systemd.services.leanix-demo = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "leanix-service";
      ExecStart = "${self.packages.${system}.helloWrapper}/bin/hello-wrapper";
    };
  };
}
```

That module is only a backend target. The Leanix source of truth should remain
the typed host/service graph.

## Delegated To NixOS and Nix

Leanix should not try to own these near term:

- complete NixOS option semantics
- module merge behavior
- systemd unit semantics
- user/group lifecycle beyond declared fields
- firewall implementation details
- service supervision behavior
- nixpkgs package build behavior
- deployment, activation, rollback, and remote host mutation

NixOS remains the operating-system realization layer. Nix remains the evaluator
and builder. Leanix should make the intended relationships explicit enough for
an agent to reason about before handing them to those layers.

## Follow-Up Decision

Implementation is explicitly deferred. The smallest future implementation ticket
would be:

```text
HostService V1: model one host/service record, validate package/check/port/user
relationships, emit an agent-legible host summary, and lower only to an
existing flake app/check target.
```

Do not start NixOS module generation until the flake-level host/service summary
has proven useful.
