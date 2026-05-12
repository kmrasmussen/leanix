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

def schemaPackageNames (packages : List (Package system)) : List String :=
  packages.map (fun package => package.name)

def validateSchemaDefaultName (schema : String) (family : String) (name : String) :
    Except SchemaError Unit := do
  if name == "default" then
    pure ()
  else
    throw (.schemaOutputMustBeDefault schema family)

def validateSchemaPackageRef (schema : String) (owner : String) (packageNames : List String)
    (packageName : String) : Except SchemaError Unit := do
  if packageNames.contains packageName then
    pure ()
  else
    throw (.schemaMissingPackageRef schema owner packageName)

def validateSchemaMinCount (schema : String) (family : String) (count actual : Nat) :
    Except SchemaError Unit := do
  if actual < count then
    throw (.schemaNeedsAtLeast schema family count)
  else
    pure ()

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

structure LibraryProject (system : System) where
  package : Package system
  extraPackages : List (Package system) := []
  devShell : DevShell system
  check : Check system
  deriving Repr, BEq

def LibraryProject.packages (project : LibraryProject system) : List (Package system) :=
  [project.package] ++ project.extraPackages

structure LibraryProject.Valid (project : LibraryProject system) : Prop where
  devShellIsDefault : project.devShell.name = "default"
  checkIsDefault : project.check.name = "default"
  checkPointsAtPackage : project.check.packageName = project.package.name
  devShellContainsPackage : project.devShell.packageNames.contains project.package.name = true

def LibraryProject.validate (project : LibraryProject system) : Except SchemaError Unit := do
  validateSchemaDefaultName "LibraryProject" "devShell" project.devShell.name
  validateSchemaDefaultName "LibraryProject" "check" project.check.name
  let packageNames := schemaPackageNames project.packages
  validateSchemaPackageRef "LibraryProject" s!"check {project.check.name}" packageNames
    project.check.packageName
  for packageName in project.devShell.packageNames do
    validateSchemaPackageRef "LibraryProject" s!"devShell {project.devShell.name}" packageNames
      packageName
  if project.check.packageName == project.package.name then
    pure ()
  else
    throw (.schemaMissingPackageRef "LibraryProject" s!"check {project.check.name}"
      project.package.name)
  if project.devShell.packageNames.contains project.package.name then
    pure ()
  else
    throw (.schemaMissingPackageRef "LibraryProject" s!"devShell {project.devShell.name}"
      project.package.name)

def LibraryProject.toOutputs : {system : System} -> LibraryProject system -> Outputs
  | .x86_64_linux, project => {
      packages
        | .x86_64_linux => project.packages
        | _ => []
      apps := fun _ => []
      devShells
        | .x86_64_linux => [project.devShell]
        | _ => []
      checks
        | .x86_64_linux => [project.check]
        | _ => []
    }
  | .aarch64_linux, project => {
      packages
        | .aarch64_linux => project.packages
        | _ => []
      apps := fun _ => []
      devShells
        | .aarch64_linux => [project.devShell]
        | _ => []
      checks
        | .aarch64_linux => [project.check]
        | _ => []
    }
  | .x86_64_darwin, project => {
      packages
        | .x86_64_darwin => project.packages
        | _ => []
      apps := fun _ => []
      devShells
        | .x86_64_darwin => [project.devShell]
        | _ => []
      checks
        | .x86_64_darwin => [project.check]
        | _ => []
    }
  | .aarch64_darwin, project => {
      packages
        | .aarch64_darwin => project.packages
        | _ => []
      apps := fun _ => []
      devShells
        | .aarch64_darwin => [project.devShell]
        | _ => []
      checks
        | .aarch64_darwin => [project.check]
        | _ => []
    }

instance : FlakeSchema (LibraryProject system) where
  toOutputs := LibraryProject.toOutputs
  validate := LibraryProject.validate
  Valid := LibraryProject.Valid

structure MultiAppProject (system : System) where
  packages : List (Package system)
  apps : List (App system)
  devShells : List (DevShell system) := []
  checks : List (Check system) := []
  deriving Repr, BEq

def MultiAppProject.appRefsResolveBool (project : MultiAppProject system) : Bool :=
  let packageNames := schemaPackageNames project.packages
  project.apps.all (fun app => packageNames.contains app.packageName)

def MultiAppProject.devShellRefsResolveBool (project : MultiAppProject system) : Bool :=
  let packageNames := schemaPackageNames project.packages
  project.devShells.all (fun shell =>
    shell.packageNames.all (fun packageName => packageNames.contains packageName))

def MultiAppProject.checkRefsResolveBool (project : MultiAppProject system) : Bool :=
  let packageNames := schemaPackageNames project.packages
  project.checks.all (fun check => packageNames.contains check.packageName)

structure MultiAppProject.Valid (project : MultiAppProject system) : Prop where
  hasMultipleApps : 2 <= project.apps.length
  appsResolve : project.appRefsResolveBool = true
  devShellsResolve : project.devShellRefsResolveBool = true
  checksResolve : project.checkRefsResolveBool = true

def MultiAppProject.validate (project : MultiAppProject system) : Except SchemaError Unit := do
  validateSchemaMinCount "MultiAppProject" "apps" 2 project.apps.length
  let packageNames := schemaPackageNames project.packages
  for app in project.apps do
    validateSchemaPackageRef "MultiAppProject" s!"app {app.name}" packageNames app.packageName
  for shell in project.devShells do
    for packageName in shell.packageNames do
      validateSchemaPackageRef "MultiAppProject" s!"devShell {shell.name}" packageNames packageName
  for check in project.checks do
    validateSchemaPackageRef "MultiAppProject" s!"check {check.name}" packageNames check.packageName

def MultiAppProject.toOutputs : {system : System} -> MultiAppProject system -> Outputs
  | .x86_64_linux, project => {
      packages
        | .x86_64_linux => project.packages
        | _ => []
      apps
        | .x86_64_linux => project.apps
        | _ => []
      devShells
        | .x86_64_linux => project.devShells
        | _ => []
      checks
        | .x86_64_linux => project.checks
        | _ => []
    }
  | .aarch64_linux, project => {
      packages
        | .aarch64_linux => project.packages
        | _ => []
      apps
        | .aarch64_linux => project.apps
        | _ => []
      devShells
        | .aarch64_linux => project.devShells
        | _ => []
      checks
        | .aarch64_linux => project.checks
        | _ => []
    }
  | .x86_64_darwin, project => {
      packages
        | .x86_64_darwin => project.packages
        | _ => []
      apps
        | .x86_64_darwin => project.apps
        | _ => []
      devShells
        | .x86_64_darwin => project.devShells
        | _ => []
      checks
        | .x86_64_darwin => project.checks
        | _ => []
    }
  | .aarch64_darwin, project => {
      packages
        | .aarch64_darwin => project.packages
        | _ => []
      apps
        | .aarch64_darwin => project.apps
        | _ => []
      devShells
        | .aarch64_darwin => project.devShells
        | _ => []
      checks
        | .aarch64_darwin => project.checks
        | _ => []
    }

instance : FlakeSchema (MultiAppProject system) where
  toOutputs := MultiAppProject.toOutputs
  validate := MultiAppProject.validate
  Valid := MultiAppProject.Valid

structure ServiceProject (system : System) where
  package : Package system
  extraPackages : List (Package system) := []
  app : App system
  devShell : DevShell system
  checks : List (Check system)
  deriving Repr, BEq

def ServiceProject.packages (project : ServiceProject system) : List (Package system) :=
  [project.package] ++ project.extraPackages

def ServiceProject.devShellRefsResolveBool (project : ServiceProject system) : Bool :=
  let packageNames := schemaPackageNames project.packages
  project.devShell.packageNames.all (fun packageName => packageNames.contains packageName)

def ServiceProject.checkRefsResolveBool (project : ServiceProject system) : Bool :=
  let packageNames := schemaPackageNames project.packages
  project.checks.all (fun check => packageNames.contains check.packageName)

def ServiceProject.checksPointAtServicePackageBool (project : ServiceProject system) : Bool :=
  project.checks.all (fun check => check.packageName == project.package.name)

structure ServiceProject.Valid (project : ServiceProject system) : Prop where
  appIsDefault : project.app.name = "default"
  devShellIsDefault : project.devShell.name = "default"
  hasChecks : 1 <= project.checks.length
  appPointsAtServicePackage : project.app.packageName = project.package.name
  devShellContainsServicePackage : project.devShell.packageNames.contains project.package.name = true
  devShellRefsResolve : project.devShellRefsResolveBool = true
  checksResolve : project.checkRefsResolveBool = true
  checksPointAtServicePackage : project.checksPointAtServicePackageBool = true

def ServiceProject.validate (project : ServiceProject system) : Except SchemaError Unit := do
  validateSchemaDefaultName "ServiceProject" "app" project.app.name
  validateSchemaDefaultName "ServiceProject" "devShell" project.devShell.name
  validateSchemaMinCount "ServiceProject" "checks" 1 project.checks.length
  let packageNames := schemaPackageNames project.packages
  validateSchemaPackageRef "ServiceProject" s!"app {project.app.name}" packageNames
    project.app.packageName
  for packageName in project.devShell.packageNames do
    validateSchemaPackageRef "ServiceProject" s!"devShell {project.devShell.name}" packageNames
      packageName
  for check in project.checks do
    validateSchemaPackageRef "ServiceProject" s!"check {check.name}" packageNames
      check.packageName
  if project.app.packageName == project.package.name then
    pure ()
  else
    throw (.schemaMissingPackageRef "ServiceProject" s!"app {project.app.name}"
      project.package.name)
  if project.devShell.packageNames.contains project.package.name then
    pure ()
  else
    throw (.schemaMissingPackageRef "ServiceProject" s!"devShell {project.devShell.name}"
      project.package.name)
  for check in project.checks do
    if check.packageName == project.package.name then
      pure ()
    else
      throw (.schemaMissingPackageRef "ServiceProject" s!"check {check.name}"
        project.package.name)

def ServiceProject.toOutputs : {system : System} -> ServiceProject system -> Outputs
  | .x86_64_linux, project => {
      packages
        | .x86_64_linux => project.packages
        | _ => []
      apps
        | .x86_64_linux => [project.app]
        | _ => []
      devShells
        | .x86_64_linux => [project.devShell]
        | _ => []
      checks
        | .x86_64_linux => project.checks
        | _ => []
    }
  | .aarch64_linux, project => {
      packages
        | .aarch64_linux => project.packages
        | _ => []
      apps
        | .aarch64_linux => [project.app]
        | _ => []
      devShells
        | .aarch64_linux => [project.devShell]
        | _ => []
      checks
        | .aarch64_linux => project.checks
        | _ => []
    }
  | .x86_64_darwin, project => {
      packages
        | .x86_64_darwin => project.packages
        | _ => []
      apps
        | .x86_64_darwin => [project.app]
        | _ => []
      devShells
        | .x86_64_darwin => [project.devShell]
        | _ => []
      checks
        | .x86_64_darwin => project.checks
        | _ => []
    }
  | .aarch64_darwin, project => {
      packages
        | .aarch64_darwin => project.packages
        | _ => []
      apps
        | .aarch64_darwin => [project.app]
        | _ => []
      devShells
        | .aarch64_darwin => [project.devShell]
        | _ => []
      checks
        | .aarch64_darwin => project.checks
        | _ => []
    }

instance : FlakeSchema (ServiceProject system) where
  toOutputs := ServiceProject.toOutputs
  validate := ServiceProject.validate
  Valid := ServiceProject.Valid

structure FormatterProject (system : System) where
  packages : List (Package system)
  formatter : Formatter system
  deriving Repr, BEq

def FormatterProject.packageNames (project : FormatterProject system) : List String :=
  schemaPackageNames project.packages

def FormatterProject.formatterRefResolvesBool (project : FormatterProject system) : Bool :=
  project.packageNames.contains project.formatter.packageName

structure FormatterProject.Valid (project : FormatterProject system) : Prop where
  formatterRefResolves : project.formatterRefResolvesBool = true

def FormatterProject.validate (project : FormatterProject system) : Except SchemaError Unit := do
  validateSchemaPackageRef "FormatterProject" "formatter" project.packageNames
    project.formatter.packageName

def FormatterProject.toOutputs : {system : System} -> FormatterProject system -> Outputs
  | .x86_64_linux, project => {
      packages
        | .x86_64_linux => project.packages
        | _ => []
      apps := fun _ => []
      devShells := fun _ => []
      checks := fun _ => []
      formatter
        | .x86_64_linux => some project.formatter
        | _ => none
    }
  | .aarch64_linux, project => {
      packages
        | .aarch64_linux => project.packages
        | _ => []
      apps := fun _ => []
      devShells := fun _ => []
      checks := fun _ => []
      formatter
        | .aarch64_linux => some project.formatter
        | _ => none
    }
  | .x86_64_darwin, project => {
      packages
        | .x86_64_darwin => project.packages
        | _ => []
      apps := fun _ => []
      devShells := fun _ => []
      checks := fun _ => []
      formatter
        | .x86_64_darwin => some project.formatter
        | _ => none
    }
  | .aarch64_darwin, project => {
      packages
        | .aarch64_darwin => project.packages
        | _ => []
      apps := fun _ => []
      devShells := fun _ => []
      checks := fun _ => []
      formatter
        | .aarch64_darwin => some project.formatter
        | _ => none
    }

instance : FlakeSchema (FormatterProject system) where
  toOutputs := FormatterProject.toOutputs
  validate := FormatterProject.validate
  Valid := FormatterProject.Valid

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
