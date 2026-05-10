import Leanix.Core

namespace Leanix

class FlakeSchema (schema : Type) where
  toOutputs : schema -> Outputs
  validate : schema -> Except String Unit
  Valid : schema -> Prop

def schemaOutputs [FlakeSchema schema] (value : schema) : Outputs :=
  FlakeSchema.toOutputs value

def validateSchema [FlakeSchema schema] (value : schema) : Except String Unit :=
  FlakeSchema.validate value

structure ValidatedSchema (schema : Type) [FlakeSchema schema] where
  value : schema
  valid : FlakeSchema.Valid value

def ValidatedSchema.outputs [FlakeSchema schema] (validated : ValidatedSchema schema) :
    Outputs :=
  schemaOutputs validated.value

structure CliProject (system : System) where
  package : Package system
  extraPackages : List (Package system) := []
  app : App system
  devShell : DevShell system
  check : Check system
  deriving Repr, BEq

structure CliProject.Valid (project : CliProject system) : Prop where
  appIsDefault : project.app.name = "default"
  devShellIsDefault : project.devShell.name = "default"
  checkIsDefault : project.check.name = "default"
  appPointsAtPackage : project.app.packageName = project.package.name
  checkPointsAtPackage : project.check.packageName = project.package.name
  devShellContainsPackage : project.devShell.packageNames.contains project.package.name = true

def CliProject.validate (project : CliProject system) : Except String Unit := do
  if project.app.name != "default" then
    throw "CliProject app output must be named default"
  else
    pure ()

  if project.devShell.name != "default" then
    throw "CliProject devShell output must be named default"
  else
    pure ()

  if project.check.name != "default" then
    throw "CliProject check output must be named default"
  else
    pure ()

  if project.app.packageName != project.package.name then
    throw "CliProject app must point at the project package"
  else
    pure ()

  if project.check.packageName != project.package.name then
    throw "CliProject check must point at the project package"
  else
    pure ()

  if !(project.devShell.packageNames.contains project.package.name) then
    throw "CliProject devShell must include the project package"
  else
    pure ()

def CliProject.toOutputs : {system : System} -> CliProject system -> Outputs
  | .x86_64_linux, project => {
      packages
        | .x86_64_linux => [project.package] ++ project.extraPackages
        | _ => []
      apps
        | .x86_64_linux => [project.app]
        | _ => []
      devShells
        | .x86_64_linux => [project.devShell]
        | _ => []
      checks
        | .x86_64_linux => [project.check]
        | _ => []
    }
  | .aarch64_linux, project => {
      packages
        | .aarch64_linux => [project.package] ++ project.extraPackages
        | _ => []
      apps
        | .aarch64_linux => [project.app]
        | _ => []
      devShells
        | .aarch64_linux => [project.devShell]
        | _ => []
      checks
        | .aarch64_linux => [project.check]
        | _ => []
    }
  | .x86_64_darwin, project => {
      packages
        | .x86_64_darwin => [project.package] ++ project.extraPackages
        | _ => []
      apps
        | .x86_64_darwin => [project.app]
        | _ => []
      devShells
        | .x86_64_darwin => [project.devShell]
        | _ => []
      checks
        | .x86_64_darwin => [project.check]
        | _ => []
    }
  | .aarch64_darwin, project => {
      packages
        | .aarch64_darwin => [project.package] ++ project.extraPackages
        | _ => []
      apps
        | .aarch64_darwin => [project.app]
        | _ => []
      devShells
        | .aarch64_darwin => [project.devShell]
        | _ => []
      checks
        | .aarch64_darwin => [project.check]
        | _ => []
    }

instance : FlakeSchema (CliProject system) where
  toOutputs := CliProject.toOutputs
  validate := CliProject.validate
  Valid := CliProject.Valid

def CliProject.validateChecked (project : CliProject system) :
    Except String (ValidatedSchema (CliProject system)) := do
  if hAppDefault : project.app.name = "default" then
    if hDevShellDefault : project.devShell.name = "default" then
      if hCheckDefault : project.check.name = "default" then
        if hAppPoints : project.app.packageName = project.package.name then
          if hCheckPoints : project.check.packageName = project.package.name then
            if hDevShellContains : project.devShell.packageNames.contains project.package.name = true then
              pure {
                value := project
                valid := {
                  appIsDefault := hAppDefault
                  devShellIsDefault := hDevShellDefault
                  checkIsDefault := hCheckDefault
                  appPointsAtPackage := hAppPoints
                  checkPointsAtPackage := hCheckPoints
                  devShellContainsPackage := hDevShellContains
                }
              }
            else
              throw "CliProject devShell must include the project package"
          else
            throw "CliProject check must point at the project package"
        else
          throw "CliProject app must point at the project package"
      else
        throw "CliProject check output must be named default"
    else
      throw "CliProject devShell output must be named default"
  else
    throw "CliProject app output must be named default"

def Flake.fromValidatedSchema [FlakeSchema schema] (description : String)
    (inputs : List (String × Input)) (validated : ValidatedSchema schema) : Flake := {
  description := description
  inputs := inputs
  outputs := validated.outputs
}

def Flake.fromSchema [FlakeSchema schema] (description : String) (inputs : List (String × Input))
    (value : schema) : Except String Flake := do
  validateSchema value
  pure {
    description := description
    inputs := inputs
    outputs := schemaOutputs value
  }

end Leanix
