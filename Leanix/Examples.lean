import Leanix.Core

namespace Leanix
namespace Examples

def nixpkgsInput : Input :=
  .flake {
    url := "github:NixOS/nixpkgs/nixos-unstable"
  }

def helloPackage : Package .x86_64_linux where
  name := "hello"
  builder := "pkgs.hello"

def helloApp : App .x86_64_linux where
  name := "hello"
  packageName := "hello"
  program := "bin/hello"

def helloDevShell : DevShell .x86_64_linux where
  name := "default"
  packageNames := ["hello"]

def helloCheck : Check .x86_64_linux where
  name := "hello"
  packageName := "hello"
  command := "hello --version > \"$out\""

def helloOutputs : Outputs where
  packages
    | .x86_64_linux => [helloPackage]
    | _ => []
  apps
    | .x86_64_linux => [helloApp]
    | _ => []
  devShells
    | .x86_64_linux => [helloDevShell]
    | _ => []
  checks
    | .x86_64_linux => [helloCheck]
    | _ => []

def helloFlake : Flake where
  description := "Leanix typed hello flake"
  inputs := [("nixpkgs", nixpkgsInput)]
  outputs := helloOutputs

end Examples
end Leanix
