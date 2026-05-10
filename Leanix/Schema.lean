import Leanix.Validate

namespace Leanix

class FlakeSchema (schema : Type) where
  toOutputs : schema -> Outputs
  validate : schema -> Except SchemaError Unit
  Valid : schema -> Prop

def schemaOutputs [FlakeSchema schema] (value : schema) : Outputs :=
  FlakeSchema.toOutputs value

def validateSchema [FlakeSchema schema] (value : schema) : Except SchemaError Unit :=
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

structure CliProject.ValidEvidence (project : CliProject system) : Type where
  valid : CliProject.Valid project

def CliProject.validateEvidence (project : CliProject system) :
    Except SchemaError (CliProject.ValidEvidence project) := do
  if hAppDefault : project.app.name = "default" then
    if hDevShellDefault : project.devShell.name = "default" then
      if hCheckDefault : project.check.name = "default" then
        if hAppPoints : project.app.packageName = project.package.name then
          if hCheckPoints : project.check.packageName = project.package.name then
            if hDevShellContains : project.devShell.packageNames.contains project.package.name = true then
              pure {
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
              throw .cliProjectDevShellMissingPackage
          else
            throw .cliProjectCheckMissingPackage
        else
          throw .cliProjectAppMissingPackage
      else
        throw .cliProjectCheckNotDefault
    else
      throw .cliProjectDevShellNotDefault
  else
    throw .cliProjectAppNotDefault

def CliProject.validate (project : CliProject system) : Except SchemaError Unit := do
  let _ ← CliProject.validateEvidence project
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
    Except SchemaError (ValidatedSchema (CliProject system)) := do
  let evidence ← CliProject.validateEvidence project
  pure {
    value := project
    valid := evidence.valid
  }

def Flake.fromValidatedSchema [FlakeSchema schema] (description : String)
    (inputs : List (String × Input)) (validated : ValidatedSchema schema) :
    Except ValidateError ValidatedFlake := do
  let validatedFlake ← Flake.validateChecked {
    description := description
    inputs := inputs
    outputs := validated.outputs
  }
  pure {
    validatedFlake with
    carriedInvariants := "FlakeSchema.Valid" :: validatedFlake.carriedInvariants
  }

def Flake.fromSchema [FlakeSchema schema] (description : String) (inputs : List (String × Input))
    (value : schema) : Except String ValidatedFlake := do
  match validateSchema value with
  | .ok _ =>
      match Flake.validateChecked {
        description := description
        inputs := inputs
        outputs := schemaOutputs value
      } with
      | .ok validatedFlake => pure validatedFlake
      | .error error => throw error.toString
  | .error error => throw error.toString

end Leanix
