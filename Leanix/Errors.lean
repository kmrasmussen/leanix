import Leanix.Core

namespace Leanix

inductive ValidateError where
  | duplicateInputNames
  | duplicateOutputNames : (system : System) -> (family : String) -> ValidateError
  | missingInputRef : (name : String) -> ValidateError
  | missingPackageRef : (system : System) -> (owner : String) -> (packageName : String) -> ValidateError
  | packageCycle : (system : System) -> (packageName : String) -> (throughPackage : String) -> ValidateError
  | sourceInputMissingHash : (name : String) -> ValidateError
  | duplicateEnvNames : (system : System) -> (owner : String) -> ValidateError
  | packageEnvUnsupportedBuild : (system : System) -> (packageName : String) -> ValidateError
  | duplicateBuildPlanArguments : (owner : String) -> ValidateError
  deriving Repr, BEq

def ValidateError.toString : ValidateError -> String
  | .duplicateInputNames => "duplicate input names"
  | .duplicateOutputNames system family =>
      s!"duplicate {family} names for {system.toNixString}"
  | .missingInputRef name =>
      s!"build expression refers to missing input {name}"
  | .missingPackageRef system owner packageName =>
      s!"{owner} for {system.toNixString} refers to missing package {packageName}"
  | .packageCycle system packageName throughPackage =>
      s!"package dependency cycle for {system.toNixString}: {packageName} reaches itself through {throughPackage}"
  | .sourceInputMissingHash name =>
      s!"source input {name} must have a narHash"
  | .duplicateEnvNames system owner =>
      s!"duplicate env var names for {owner} on {system.toNixString}"
  | .packageEnvUnsupportedBuild system packageName =>
      s!"package {packageName} for {system.toNixString} can only set env vars on runCommand or runSteps builders"
  | .duplicateBuildPlanArguments owner =>
      s!"duplicate build plan arguments for {owner}"

instance : ToString ValidateError where
  toString := ValidateError.toString

inductive SchemaError where
  | cliProjectAppNotDefault
  | cliProjectDevShellNotDefault
  | cliProjectCheckNotDefault
  | cliProjectAppMissingPackage
  | cliProjectCheckMissingPackage
  | cliProjectDevShellMissingPackage
  | multiSystemNeedsTwoSystems
  | multiSystemSystemInvalid : (system : System) -> (error : String) -> SchemaError
  | schemaOutputMustBeDefault : (schema : String) -> (family : String) -> SchemaError
  | schemaMissingPackageRef : (schema : String) -> (owner : String) -> (packageName : String) -> SchemaError
  | schemaNeedsAtLeast : (schema : String) -> (family : String) -> (count : Nat) -> SchemaError
  deriving Repr, BEq

def SchemaError.toString : SchemaError -> String
  | .cliProjectAppNotDefault => "CliProject app output must be named default"
  | .cliProjectDevShellNotDefault => "CliProject devShell output must be named default"
  | .cliProjectCheckNotDefault => "CliProject check output must be named default"
  | .cliProjectAppMissingPackage => "CliProject app must point at the project package"
  | .cliProjectCheckMissingPackage => "CliProject check must point at the project package"
  | .cliProjectDevShellMissingPackage => "CliProject devShell must include the project package"
  | .multiSystemNeedsTwoSystems => "MultiSystemCliProject must include at least two active systems"
  | .multiSystemSystemInvalid system error =>
      s!"MultiSystemCliProject {system.toNixString} invalid: {error}"
  | .schemaOutputMustBeDefault schema family =>
      s!"{schema} {family} output must be named default"
  | .schemaMissingPackageRef schema owner packageName =>
      s!"{schema} {owner} must point at an existing package {packageName}"
  | .schemaNeedsAtLeast schema family count =>
      s!"{schema} must include at least {count} {family}"

instance : ToString SchemaError where
  toString := SchemaError.toString

end Leanix
