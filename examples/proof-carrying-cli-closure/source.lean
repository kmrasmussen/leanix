import Leanix.Core
import Leanix.Schema

namespace Leanix
namespace ProofCarryingCliClosure

def helloToolPackage : Package .x86_64_linux where
  name := "helloTool"
  build := .nixpkgs "hello"

def helloWrapperPackage : Package .x86_64_linux where
  name := "helloWrapper"
  build := .runSteps "hello-wrapper" [.package "helloTool"] [
    .mkdir "$out/bin",
    .writeFile "$out/bin/hello-wrapper" (
      "#!/bin/sh\n" ++
      "${self.packages.${system}.helloTool}/bin/hello --version"
    ),
    .chmodExecutable "$out/bin/hello-wrapper"
  ]

def showcaseCliProject : CliProject .x86_64_linux where
  package := helloWrapperPackage
  extraPackages := [helloToolPackage]
  app := {
    name := "default"
    packageName := "helloWrapper"
    program := "bin/hello-wrapper"
  }
  devShell := {
    name := "default"
    packageNames := ["helloWrapper"]
  }
  check := {
    name := "default"
    packageName := "helloWrapper"
    command := "hello-wrapper > \"$out\""
  }

def showcaseValidatedSchema : Except String (ValidatedSchema (CliProject .x86_64_linux)) :=
  CliProject.validateChecked showcaseCliProject

end ProofCarryingCliClosure
end Leanix
