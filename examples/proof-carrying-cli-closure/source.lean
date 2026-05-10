import Leanix.Core
import Leanix.Schema
import Leanix.Validate

namespace Leanix
namespace ProofCarryingCliClosure

def helloToolPackage : Package .x86_64_linux where
  name := "helloTool"
  build := .nixpkgs "hello"

def helloWrapperPackage : Package .x86_64_linux where
  name := "helloWrapper"
  build := .runSteps "hello-wrapper" [.package "helloTool"] [
    .installExecutableTextScript "$out/bin/hello-wrapper" (
      .concat [
        .literal "#!/bin/sh\n",
        .package "helloTool",
        .literal "/bin/hello --version\n"
      ]
    )
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

def showcaseValidatedSchema : Except SchemaError (ValidatedSchema (CliProject .x86_64_linux)) :=
  CliProject.validateChecked showcaseCliProject

def checkedPackageGraph : CheckedPackageGraph .x86_64_linux where
  packages := [helloWrapperPackage, helloToolPackage]
  valid := {
    refsResolve := by native_decide
    acyclicByFuel := by native_decide
  }

end ProofCarryingCliClosure
end Leanix
