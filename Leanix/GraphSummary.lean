import Leanix.Artifact

namespace Leanix

structure GraphPackageSummary where
  system : System
  name : String
  builder : String
  packageEdges : List String
  inputEdges : List String
  deriving Repr, BEq

structure GraphAppSummary where
  system : System
  name : String
  packageName : String
  program : String
  deriving Repr, BEq

structure GraphDevShellSummary where
  system : System
  name : String
  packageNames : List String
  deriving Repr, BEq

structure GraphCheckSummary where
  system : System
  name : String
  packageName : String
  commandKind : String
  commandPackageEdges : List String
  commandInputEdges : List String
  deriving Repr, BEq

structure GraphFormatterSummary where
  system : System
  packageName : String
  deriving Repr, BEq

structure RawEscapeSummary where
  system : System
  owner : String
  escape : String
  deriving Repr, BEq

structure GraphSummary where
  formatVersion : Nat
  summaryKind : String
  derivedFrom : String
  escapePolicy : EscapePolicy
  policies : List String
  systems : List System
  inputs : List ArtifactInput
  packages : List GraphPackageSummary
  apps : List GraphAppSummary
  devShells : List GraphDevShellSummary
  checks : List GraphCheckSummary
  formatters : List GraphFormatterSummary
  rawEscapeHatches : List RawEscapeSummary
  checkedInvariants : List String
  deriving Repr, BEq

mutual
def buildTextInputRefs : BuildText -> List String
  | .literal _ => []
  | .package _ => []
  | .inputPath name => [name]
  | .outPath => []
  | .concat parts => buildTextInputRefsList parts

def buildTextInputRefsList : List BuildText -> List String
  | [] => []
  | part :: rest => buildTextInputRefs part ++ buildTextInputRefsList rest
end

mutual
def buildExprInputRefs : BuildExpr -> List String
  | .nixpkgs _ => []
  | .inputPath name => [name]
  | .package _ => []
  | .runCommand _ nativeBuildInputs _ => buildExprInputRefsList nativeBuildInputs
  | .runSteps _ nativeBuildInputs steps =>
      buildExprInputRefsList nativeBuildInputs ++ buildStepInputRefsList steps

def buildExprInputRefsList : List BuildExpr -> List String
  | [] => []
  | input :: rest => buildExprInputRefs input ++ buildExprInputRefsList rest

def buildStepInputRefs : BuildStep -> List String
  | .copySource source _ => buildExprInputRefs source
  | .installTextFile _ content => buildTextInputRefs content
  | .installExecutableScript _ _ => []
  | .installExecutableTextScript _ content => buildTextInputRefs content
  | .buildLeanProject _ => []
  | .mkdir _ => []
  | .copyFile _ _ => []
  | .writeFile _ _ => []
  | .writeTextFile _ content => buildTextInputRefs content
  | .chmodExecutable _ => []
  | .run _ => []

def buildStepInputRefsList : List BuildStep -> List String
  | [] => []
  | step :: rest => buildStepInputRefs step ++ buildStepInputRefsList rest
end

def checkCommandKind : CheckCommand -> String
  | .rawShell _ => "rawShell"
  | .packageExecutableToOutput _ => "packageExecutableToOutput"
  | .inputPathExists _ => "inputPathExists"

def GraphPackageSummary.toJsonLines (package : GraphPackageSummary) : List String :=
  [
    jsonField "system" (jsonString package.system.toNixString) ++ ",",
    jsonField "name" (jsonString package.name) ++ ",",
    jsonField "builder" (jsonString package.builder) ++ ","
  ] ++
  jsonArrayField "packageEdges" (jsonStringArray package.packageEdges) true ++
  jsonArrayField "inputEdges" (jsonStringArray package.inputEdges) false

def GraphAppSummary.toJsonLines (app : GraphAppSummary) : List String :=
  jsonObjectFieldLines [
    jsonField "system" (jsonString app.system.toNixString),
    jsonField "name" (jsonString app.name),
    jsonField "packageName" (jsonString app.packageName),
    jsonField "program" (jsonString app.program)
  ]

def GraphDevShellSummary.toJsonLines (shell : GraphDevShellSummary) : List String :=
  [
    jsonField "system" (jsonString shell.system.toNixString) ++ ",",
    jsonField "name" (jsonString shell.name) ++ ","
  ] ++
  jsonArrayField "packageNames" (jsonStringArray shell.packageNames) false

def GraphCheckSummary.toJsonLines (check : GraphCheckSummary) : List String :=
  [
    jsonField "system" (jsonString check.system.toNixString) ++ ",",
    jsonField "name" (jsonString check.name) ++ ",",
    jsonField "packageName" (jsonString check.packageName) ++ ",",
    jsonField "commandKind" (jsonString check.commandKind) ++ ","
  ] ++
  jsonArrayField "commandPackageEdges" (jsonStringArray check.commandPackageEdges) true ++
  jsonArrayField "commandInputEdges" (jsonStringArray check.commandInputEdges) false

def GraphFormatterSummary.toJsonLines (formatter : GraphFormatterSummary) : List String :=
  jsonObjectFieldLines [
    jsonField "system" (jsonString formatter.system.toNixString),
    jsonField "packageName" (jsonString formatter.packageName)
  ]

def RawEscapeSummary.toJsonLines (escape : RawEscapeSummary) : List String :=
  jsonObjectFieldLines [
    jsonField "system" (jsonString escape.system.toNixString),
    jsonField "owner" (jsonString escape.owner),
    jsonField "escape" (jsonString escape.escape)
  ]

def formatterSummary? (system : System) : Option (Formatter system) -> Option GraphFormatterSummary
  | none => none
  | some formatter => some {
      system := system
      packageName := formatter.packageName
    }

def optionToList : Option α -> List α
  | none => []
  | some value => [value]

def listConcatMap (f : α -> List β) : List α -> List β
  | [] => []
  | value :: rest => f value ++ listConcatMap f rest

def uniqueStrings : List String -> List String
  | [] => []
  | value :: rest =>
      let dedupedRest := uniqueStrings rest
      if dedupedRest.contains value then
        dedupedRest
      else
        value :: dedupedRest

def hasSystemOutputs (outputs : CheckedSystemOutputs system) : Bool :=
  !(outputs.packages.isEmpty) ||
    !(outputs.apps.isEmpty) ||
    !(outputs.devShells.isEmpty) ||
    !(outputs.checks.isEmpty) ||
    outputs.formatter?.isSome

mutual
def buildExprRawEscapes (system : System) (owner : String) : BuildExpr -> List RawEscapeSummary
  | .nixpkgs _ => []
  | .inputPath _ => []
  | .package _ => []
  | .runCommand name nativeBuildInputs _ =>
      [{ system := system, owner := owner, escape := s!"runCommand {name}" }] ++
      buildExprRawEscapesList system owner nativeBuildInputs
  | .runSteps _ nativeBuildInputs steps =>
      buildExprRawEscapesList system owner nativeBuildInputs ++
      buildStepRawEscapesList system owner steps

def buildExprRawEscapesList (system : System) (owner : String) :
    List BuildExpr -> List RawEscapeSummary
  | [] => []
  | input :: rest =>
      buildExprRawEscapes system owner input ++ buildExprRawEscapesList system owner rest

def buildStepRawEscapes (system : System) (owner : String) : BuildStep -> List RawEscapeSummary
  | .copySource source _ => buildExprRawEscapes system owner source
  | .installTextFile _ _ => []
  | .installExecutableScript path _ =>
      [{ system := system, owner := owner, escape := s!"installExecutableScript {path}" }]
  | .installExecutableTextScript _ _ => []
  | .buildLeanProject _ => []
  | .mkdir _ => []
  | .copyFile _ _ => []
  | .writeFile path _ => [{ system := system, owner := owner, escape := s!"writeFile {path}" }]
  | .writeTextFile _ _ => []
  | .chmodExecutable _ => []
  | .run command => [{ system := system, owner := owner, escape := s!"run step {command}" }]

def buildStepRawEscapesList (system : System) (owner : String) :
    List BuildStep -> List RawEscapeSummary
  | [] => []
  | step :: rest =>
      buildStepRawEscapes system owner step ++ buildStepRawEscapesList system owner rest
end

def checkCommandRawEscapes (system : System) (owner : String) :
    CheckCommand -> List RawEscapeSummary
  | .rawShell _ => [{ system := system, owner := owner, escape := "raw shell command" }]
  | .packageExecutableToOutput _ => []
  | .inputPathExists _ => []

def checkedSystemSummaries (outputs : CheckedSystemOutputs system) :
    List GraphPackageSummary ×
      List GraphAppSummary ×
      List GraphDevShellSummary ×
      List GraphCheckSummary ×
      List GraphFormatterSummary ×
      List RawEscapeSummary :=
  let packageSummaries := outputs.packages.map fun package => {
    system := system
    name := package.name
    builder := buildExprKind package.build
    packageEdges := uniqueStrings (packageDeps package)
    inputEdges := uniqueStrings (buildExprInputRefs package.build)
  }
  let appSummaries := outputs.apps.map fun app => {
    system := system
    name := app.name
    packageName := app.packageName
    program := app.program
  }
  let shellSummaries := outputs.devShells.map fun shell => {
    system := system
    name := shell.name
    packageNames := shell.packageNames
  }
  let checkSummaries := outputs.checks.map fun check => {
    system := system
    name := check.name
    packageName := check.packageName
    commandKind := checkCommandKind check.command
    commandPackageEdges := uniqueStrings (checkCommandPackageRefs check.command)
    commandInputEdges := uniqueStrings (checkCommandInputRefs check.command)
  }
  let formatterSummaries := optionToList (formatterSummary? system outputs.formatter?)
  let packageEscapes := listConcatMap (fun package =>
    buildExprRawEscapes system s!"package {package.name}" package.build
  ) outputs.packages
  let checkEscapes := listConcatMap (fun check =>
    checkCommandRawEscapes system s!"check {check.name}" check.command
  ) outputs.checks
  (packageSummaries, appSummaries, shellSummaries, checkSummaries, formatterSummaries,
    packageEscapes ++ checkEscapes)

def collectCheckedSummaries :
    List AnyCheckedSystemOutputs ->
      List System ×
        List GraphPackageSummary ×
        List GraphAppSummary ×
        List GraphDevShellSummary ×
        List GraphCheckSummary ×
        List GraphFormatterSummary ×
        List RawEscapeSummary
  | [] => ([], [], [], [], [], [], [])
  | @AnyCheckedSystemOutputs.mk system outputs :: rest =>
      let (systems, packages, apps, devShells, checks, formatters, escapes) :=
        collectCheckedSummaries rest
      let systemList := if hasSystemOutputs outputs then [system] else []
      let (systemPackages, systemApps, systemDevShells, systemChecks, systemFormatters,
        systemEscapes) := checkedSystemSummaries outputs
      (systemList ++ systems,
        systemPackages ++ packages,
        systemApps ++ apps,
        systemDevShells ++ devShells,
        systemChecks ++ checks,
        systemFormatters ++ formatters,
        systemEscapes ++ escapes)

def graphSummaryPolicies : List String := [
  "development: permits raw escape hatches, local development sources, and floating flake inputs",
  "ci: rejects raw escape hatches and impure local sources",
  "strict-artifact: rejects raw escape hatches, local/impure sources, and floating flake inputs without direct pin evidence"
]

def GraphSummary.fromValidated (validated : ValidatedFlake) : GraphSummary :=
  let (systems, packages, apps, devShells, checks, formatters, escapes) :=
    collectCheckedSummaries validated.checkedOutputs
  {
    formatVersion := 1
    summaryKind := "experimental-graph-summary"
    derivedFrom := "checked-leanix-values"
    escapePolicy := .development
    policies := graphSummaryPolicies
    systems := systems
    inputs := validated.flake.inputs.map inputArtifact
    packages := packages
    apps := apps
    devShells := devShells
    checks := checks
    formatters := formatters
    rawEscapeHatches := escapes
    checkedInvariants := validated.carriedInvariants
  }

def GraphSummary.toJson (summary : GraphSummary) : String :=
  joinWith "\n" <| [
    "{",
    "  " ++ jsonField "formatVersion" (toString summary.formatVersion) ++ ",",
    "  " ++ jsonField "summaryKind" (jsonString summary.summaryKind) ++ ",",
    "  " ++ jsonField "derivedFrom" (jsonString summary.derivedFrom) ++ ",",
    "  " ++ jsonField "escapePolicy" (jsonString summary.escapePolicy.toString) ++ ","
  ] ++
  indentLines "  " (jsonArrayField "policies" (jsonStringArray summary.policies) true) ++
  indentLines "  " (jsonArrayField "systems" (jsonStringArray (summary.systems.map System.toNixString)) true) ++
  indentLines "  " (jsonArrayField "inputs" (jsonObjectArray (summary.inputs.map ArtifactInput.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "packages" (jsonObjectArray (summary.packages.map GraphPackageSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "apps" (jsonObjectArray (summary.apps.map GraphAppSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "devShells" (jsonObjectArray (summary.devShells.map GraphDevShellSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "checks" (jsonObjectArray (summary.checks.map GraphCheckSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "formatters" (jsonObjectArray (summary.formatters.map GraphFormatterSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "rawEscapeHatches" (jsonObjectArray (summary.rawEscapeHatches.map RawEscapeSummary.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "checkedInvariants" (jsonStringArray summary.checkedInvariants) false) ++
  [
    "}",
    ""
  ]

def renderGraphSummary (validated : ValidatedFlake) : String :=
  (GraphSummary.fromValidated validated).toJson

end Leanix
