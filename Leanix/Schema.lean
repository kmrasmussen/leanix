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

structure MultiSystemCliProject where
  name : String
  x86_64Linux : Option (CliProject .x86_64_linux) := none
  aarch64Linux : Option (CliProject .aarch64_linux) := none
  x86_64Darwin : Option (CliProject .x86_64_darwin) := none
  aarch64Darwin : Option (CliProject .aarch64_darwin) := none

def optionCount : Option α -> Nat
  | none => 0
  | some _ => 1

def MultiSystemCliProject.activeSystemCount (project : MultiSystemCliProject) : Nat :=
  optionCount project.x86_64Linux +
  optionCount project.aarch64Linux +
  optionCount project.x86_64Darwin +
  optionCount project.aarch64Darwin

structure MultiSystemCliProject.Valid (project : MultiSystemCliProject) : Prop where
  hasMultipleSystems : 2 <= project.activeSystemCount

def MultiSystemCliProject.validateOne (system : System) (project : CliProject system) :
    Except SchemaError Unit := do
  match CliProject.validate project with
  | .ok _ => pure ()
  | .error error => throw (.multiSystemSystemInvalid system error.toString)

def MultiSystemCliProject.validate (project : MultiSystemCliProject) :
    Except SchemaError Unit := do
  if project.activeSystemCount < 2 then
    throw .multiSystemNeedsTwoSystems
  else
    pure ()

  match project.x86_64Linux with
  | some value => MultiSystemCliProject.validateOne .x86_64_linux value
  | none => pure ()
  match project.aarch64Linux with
  | some value => MultiSystemCliProject.validateOne .aarch64_linux value
  | none => pure ()
  match project.x86_64Darwin with
  | some value => MultiSystemCliProject.validateOne .x86_64_darwin value
  | none => pure ()
  match project.aarch64Darwin with
  | some value => MultiSystemCliProject.validateOne .aarch64_darwin value
  | none => pure ()

def MultiSystemCliProject.toOutputs (project : MultiSystemCliProject) : Outputs where
  packages
    | .x86_64_linux =>
        match project.x86_64Linux with
        | some value => [value.package] ++ value.extraPackages
        | none => []
    | .aarch64_linux =>
        match project.aarch64Linux with
        | some value => [value.package] ++ value.extraPackages
        | none => []
    | .x86_64_darwin =>
        match project.x86_64Darwin with
        | some value => [value.package] ++ value.extraPackages
        | none => []
    | .aarch64_darwin =>
        match project.aarch64Darwin with
        | some value => [value.package] ++ value.extraPackages
        | none => []
  apps
    | .x86_64_linux => project.x86_64Linux.map (fun value => [value.app]) |>.getD []
    | .aarch64_linux => project.aarch64Linux.map (fun value => [value.app]) |>.getD []
    | .x86_64_darwin => project.x86_64Darwin.map (fun value => [value.app]) |>.getD []
    | .aarch64_darwin => project.aarch64Darwin.map (fun value => [value.app]) |>.getD []
  devShells
    | .x86_64_linux => project.x86_64Linux.map (fun value => [value.devShell]) |>.getD []
    | .aarch64_linux => project.aarch64Linux.map (fun value => [value.devShell]) |>.getD []
    | .x86_64_darwin => project.x86_64Darwin.map (fun value => [value.devShell]) |>.getD []
    | .aarch64_darwin => project.aarch64Darwin.map (fun value => [value.devShell]) |>.getD []
  checks
    | .x86_64_linux => project.x86_64Linux.map (fun value => [value.check]) |>.getD []
    | .aarch64_linux => project.aarch64Linux.map (fun value => [value.check]) |>.getD []
    | .x86_64_darwin => project.x86_64Darwin.map (fun value => [value.check]) |>.getD []
    | .aarch64_darwin => project.aarch64Darwin.map (fun value => [value.check]) |>.getD []

instance : FlakeSchema MultiSystemCliProject where
  toOutputs := MultiSystemCliProject.toOutputs
  validate := MultiSystemCliProject.validate
  Valid := MultiSystemCliProject.Valid

def MultiSystemCliProject.validateChecked (project : MultiSystemCliProject) :
    Except SchemaError (ValidatedSchema MultiSystemCliProject) := do
  MultiSystemCliProject.validate project
  if h : 2 <= project.activeSystemCount then
    pure {
      value := project
      valid := {
        hasMultipleSystems := h
      }
    }
  else
    throw .multiSystemNeedsTwoSystems

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
