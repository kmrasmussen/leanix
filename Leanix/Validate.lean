import Leanix.Errors

namespace Leanix

def hasDuplicateString : List String -> Bool
  | [] => false
  | name :: rest => rest.contains name || hasDuplicateString rest

def validateUniqueNames (system : System) (family : String) (names : List String) :
    Except ValidateError Unit := do
  if hasDuplicateString names then
    throw (.duplicateOutputNames system family)
  else
    pure ()

def validateEnvVars (system : System) (owner : String) (env : List EnvVar) :
    Except ValidateError Unit := do
  if hasDuplicateString (env.map (fun var => var.name)) then
    throw (.duplicateEnvNames system owner)
  else
    pure ()

def validatePackageEnvVars (system : System) (package : Package system) :
    Except ValidateError Unit := do
  validateEnvVars system s!"package {package.name}" package.env
  match package.env, package.build with
  | [], _ => pure ()
  | _ :: _, .runCommand _ _ _ => pure ()
  | _ :: _, .runSteps _ _ _ => pure ()
  | _ :: _, _ => throw (.packageEnvUnsupportedBuild system package.name)

def validatePackageRef (system : System) (packageNames : List String) (owner : String)
    (packageName : String) : Except ValidateError Unit := do
  if packageNames.contains packageName then
    pure ()
  else
    throw (.missingPackageRef system owner packageName)

def validateInputRef (inputNames : List String) (name : String) : Except ValidateError Unit := do
  if inputNames.contains name then
    pure ()
  else
    throw (.missingInputRef name)

def validateBuildPlanInputRefs (inputNames : List String) (plan : BuildPlan) :
    Except ValidateError Unit := do
  for inputName in plan.inputRefs do
    validateInputRef inputNames inputName

def validateBuildPlanPackageRefs (system : System) (packageNames : List String) (owner : String)
    (plan : BuildPlan) : Except ValidateError Unit := do
  for packageName in plan.packageRefs do
    validatePackageRef system packageNames owner packageName

def validateBuildPlanArguments (owner : String) (plan : BuildPlan) :
    Except ValidateError Unit := do
  match plan with
  | .executableTextWrapper args =>
      if hasDuplicateString args.arguments then
        throw (.duplicateBuildPlanArguments owner)
      else
        pure ()
  | _ => pure ()

def validateBuildPlanRefs (system : System) (inputNames packageNames : List String)
    (owner : String) (plan : BuildPlan) : Except ValidateError Unit := do
  validateBuildPlanArguments owner plan
  validateBuildPlanInputRefs inputNames plan
  validateBuildPlanPackageRefs system packageNames owner plan

mutual
def validateBuildTextInputRefs (inputNames : List String) : BuildText -> Except ValidateError Unit
  | .literal _ => pure ()
  | .package _ => pure ()
  | .inputPath name =>
      validateInputRef inputNames name
  | .outPath => pure ()
  | .concat parts => validateBuildTextInputRefsList inputNames parts

def validateBuildTextInputRefsList (inputNames : List String) :
    List BuildText -> Except ValidateError Unit
  | [] => pure ()
  | part :: rest => do
      validateBuildTextInputRefs inputNames part
      validateBuildTextInputRefsList inputNames rest

def validateBuildExprInputRefs (inputNames : List String) : BuildExpr -> Except ValidateError Unit
  | .nixpkgs _ => pure ()
  | .inputPath name =>
      if inputNames.contains name then
        pure ()
      else
        throw (.missingInputRef name)
  | .package _ => pure ()
  | .runCommand _ nativeBuildInputs _ => do
      for input in nativeBuildInputs do
        validateBuildExprInputRefs inputNames input
  | .runSteps _ nativeBuildInputs steps => do
      for input in nativeBuildInputs do
        validateBuildExprInputRefs inputNames input
      for step in steps do
        validateBuildStepInputRefs inputNames step

def validateBuildStepInputRefs (inputNames : List String) : BuildStep -> Except ValidateError Unit
  | .copySource source _ => validateBuildExprInputRefs inputNames source
  | .installTextFile _ content => validateBuildTextInputRefs inputNames content
  | .installExecutableScript _ _ => pure ()
  | .installExecutableTextScript _ content => validateBuildTextInputRefs inputNames content
  | .buildLeanProject _ => pure ()
  | .mkdir _ => pure ()
  | .copyFile _ _ => pure ()
  | .writeFile _ _ => pure ()
  | .writeTextFile _ content => validateBuildTextInputRefs inputNames content
  | .chmodExecutable _ => pure ()
  | .run _ => pure ()
end

mutual
def buildTextPackageRefs : BuildText -> List String
  | .literal _ => []
  | .package name => [name]
  | .inputPath _ => []
  | .outPath => []
  | .concat parts => buildTextPackageRefsList parts

def buildTextPackageRefsList : List BuildText -> List String
  | [] => []
  | part :: rest => buildTextPackageRefs part ++ buildTextPackageRefsList rest

def buildExprPackageRefs : BuildExpr -> List String
  | .nixpkgs _ => []
  | .inputPath _ => []
  | .package name => [name]
  | .runCommand _ nativeBuildInputs _ =>
      buildExprPackageRefsList nativeBuildInputs
  | .runSteps _ nativeBuildInputs steps =>
      buildExprPackageRefsList nativeBuildInputs ++ buildStepPackageRefsList steps

def buildExprPackageRefsList : List BuildExpr -> List String
  | [] => []
  | input :: rest => buildExprPackageRefs input ++ buildExprPackageRefsList rest

def buildStepPackageRefs : BuildStep -> List String
  | .copySource source _ => buildExprPackageRefs source
  | .installTextFile _ content => buildTextPackageRefs content
  | .installExecutableScript _ _ => []
  | .installExecutableTextScript _ content => buildTextPackageRefs content
  | .buildLeanProject _ => []
  | .mkdir _ => []
  | .copyFile _ _ => []
  | .writeFile _ _ => []
  | .writeTextFile _ content => buildTextPackageRefs content
  | .chmodExecutable _ => []
  | .run _ => []

def buildStepPackageRefsList : List BuildStep -> List String
  | [] => []
  | step :: rest => buildStepPackageRefs step ++ buildStepPackageRefsList rest
end

mutual
def validateBuildTextPackageRefs (system : System) (packageNames : List String) (owner : String) :
    BuildText -> Except ValidateError Unit
  | .literal _ => pure ()
  | .package name => validatePackageRef system packageNames owner name
  | .inputPath _ => pure ()
  | .outPath => pure ()
  | .concat parts => validateBuildTextPackageRefsList system packageNames owner parts

def validateBuildTextPackageRefsList (system : System) (packageNames : List String)
    (owner : String) : List BuildText -> Except ValidateError Unit
  | [] => pure ()
  | part :: rest => do
      validateBuildTextPackageRefs system packageNames owner part
      validateBuildTextPackageRefsList system packageNames owner rest

def validateBuildExprPackageRefs (system : System) (packageNames : List String) (owner : String) :
    BuildExpr -> Except ValidateError Unit
  | .nixpkgs _ => pure ()
  | .inputPath _ => pure ()
  | .package name => validatePackageRef system packageNames owner name
  | .runCommand _ nativeBuildInputs _ => do
      for input in nativeBuildInputs do
        validateBuildExprPackageRefs system packageNames owner input
  | .runSteps _ nativeBuildInputs steps => do
      for input in nativeBuildInputs do
        validateBuildExprPackageRefs system packageNames owner input
      for step in steps do
        validateBuildStepPackageRefs system packageNames owner step

def validateBuildStepPackageRefs (system : System) (packageNames : List String) (owner : String) :
    BuildStep -> Except ValidateError Unit
  | .copySource source _ => validateBuildExprPackageRefs system packageNames owner source
  | .installTextFile _ content => validateBuildTextPackageRefs system packageNames owner content
  | .installExecutableScript _ _ => pure ()
  | .installExecutableTextScript _ content =>
      validateBuildTextPackageRefs system packageNames owner content
  | .buildLeanProject _ => pure ()
  | .mkdir _ => pure ()
  | .copyFile _ _ => pure ()
  | .writeFile _ _ => pure ()
  | .writeTextFile _ content => validateBuildTextPackageRefs system packageNames owner content
  | .chmodExecutable _ => pure ()
  | .run _ => pure ()
end

def checkCommandPackageRefs : CheckCommand -> List String
  | .rawShell _ => []
  | .packageExecutableToOutput command => [command.packageName]
  | .inputPathExists _ => []

def checkCommandInputRefs : CheckCommand -> List String
  | .rawShell _ => []
  | .packageExecutableToOutput _ => []
  | .inputPathExists command => [command.inputName]

def validateCheckCommandPackageRefs (system : System) (packageNames : List String)
    (owner : String) (command : CheckCommand) : Except ValidateError Unit := do
  for packageName in checkCommandPackageRefs command do
    validatePackageRef system packageNames owner packageName

def validateCheckCommandInputRefs (inputNames : List String) (command : CheckCommand) :
    Except ValidateError Unit := do
  for inputName in checkCommandInputRefs command do
    validateInputRef inputNames inputName

def findPackageByName? (packages : List (Package system)) (name : String) :
    Option (Package system) :=
  packages.find? (fun package => package.name == name)

def packageDeps (package : Package system) : List String :=
  buildExprPackageRefs package.build

def reachesPackageWithFuel (packages : List (Package system)) (target : String)
    (current : String) : Nat -> Bool
  | 0 => false
  | fuel + 1 =>
      if current == target then
        true
      else
        match findPackageByName? packages current with
        | none => false
        | some package =>
            (packageDeps package).any fun next =>
              reachesPackageWithFuel packages target next fuel

def validateNoPackageCycles (system : System) (packages : List (Package system)) :
    Except ValidateError Unit := do
  let fuel := packages.length + 1
  for package in packages do
    for dep in packageDeps package do
      if reachesPackageWithFuel packages package.name dep fuel then
        throw (.packageCycle system package.name dep)
      else
        pure ()

namespace PackageClosure

def packageNames (packages : List (Package system)) : List String :=
  packages.map (fun package => package.name)

def refsResolveBool (packages : List (Package system)) : Bool :=
  packages.all fun package =>
    (packageDeps package).all fun packageName =>
      (packageNames packages).contains packageName

def acyclicByFuelBool (packages : List (Package system)) : Bool :=
  packages.all fun package =>
    (packageDeps package).all fun dep =>
      !(reachesPackageWithFuel packages package.name dep (packages.length + 1))

inductive ReferencesResolve (packages : List (Package system)) : Prop where
  | checked : refsResolveBool packages = true -> ReferencesResolve packages

inductive NoFuelBoundedCycles (packages : List (Package system)) : Prop where
  | checked : acyclicByFuelBool packages = true -> NoFuelBoundedCycles packages

def ReferencesResolve.toCheckedBool :
    ReferencesResolve (system := system) packages -> refsResolveBool packages = true
  | .checked proof => proof

def NoFuelBoundedCycles.toCheckedBool :
    NoFuelBoundedCycles (system := system) packages -> acyclicByFuelBool packages = true
  | .checked proof => proof

structure Valid (packages : List (Package system)) : Prop where
  referencesResolve : ReferencesResolve packages
  noFuelBoundedCycles : NoFuelBoundedCycles packages

end PackageClosure

structure CheckedPackageGraph (system : System) where
  packages : List (Package system)
  valid : PackageClosure.Valid packages

def CheckedPackageGraph.refsResolve (graph : CheckedPackageGraph system) :
    PackageClosure.refsResolveBool graph.packages = true :=
  graph.valid.referencesResolve.toCheckedBool

def CheckedPackageGraph.acyclicByFuel (graph : CheckedPackageGraph system) :
    PackageClosure.acyclicByFuelBool graph.packages = true :=
  graph.valid.noFuelBoundedCycles.toCheckedBool

def checkPackageGraph (system : System) (packages : List (Package system)) :
    Except ValidateError (CheckedPackageGraph system) := do
  let packageNames := PackageClosure.packageNames packages
  for package in packages do
    validateBuildExprPackageRefs system packageNames s!"package {package.name}" package.build

  validateNoPackageCycles system packages

  if hRefs : PackageClosure.refsResolveBool packages = true then
    if hAcyclic : PackageClosure.acyclicByFuelBool packages = true then
      pure {
        packages := packages
        valid := {
          referencesResolve := .checked hRefs
          noFuelBoundedCycles := .checked hAcyclic
        }
      }
    else
      throw (.packageCycle system "unknown" "unknown")
  else
    throw (.missingPackageRef system "package graph" "unknown")

def validateSystemOutputs (flake : Flake) (system : System) : Except ValidateError Unit := do
  let packages := flake.outputs.packages system
  let apps := flake.outputs.apps system
  let devShells := flake.outputs.devShells system
  let checks := flake.outputs.checks system
  let formatter? := flake.outputs.formatter system
  let packageNames := packages.map (fun package => package.name)
  let inputNames := flake.inputs.map (fun input => input.fst)

  validateUniqueNames system "package" packageNames
  validateUniqueNames system "app" (apps.map (fun app => app.name))
  validateUniqueNames system "devShell" (devShells.map (fun shell => shell.name))
  validateUniqueNames system "check" (checks.map (fun check => check.name))

  for package in packages do
    validateBuildExprInputRefs inputNames package.build

  let _checkedPackages ← checkPackageGraph system packages

  for package in packages do
    validatePackageEnvVars system package

  for app in apps do
    validatePackageRef system packageNames s!"app {app.name}" app.packageName

  for shell in devShells do
    validateEnvVars system s!"devShell {shell.name}" shell.env
    for packageName in shell.packageNames do
      validatePackageRef system packageNames s!"devShell {shell.name}" packageName

  for check in checks do
    validatePackageRef system packageNames s!"check {check.name}" check.packageName
    validateCheckCommandPackageRefs system packageNames s!"check command {check.name}" check.command
    validateCheckCommandInputRefs inputNames check.command

  match formatter? with
  | none => pure ()
  | some formatter =>
      validatePackageRef system packageNames "formatter" formatter.packageName

def validateInput (name : String) (input : Input) : Except ValidateError Unit := do
  match input with
  | .flake _ => pure ()
  | .localDevSource _ => pure ()
  | .impureLocalSource _ => pure ()
  | .source pin =>
      match pin.narHash? with
      | some _ => pure ()
      | none => throw (.sourceInputMissingHash name)

def validateFlake (flake : Flake) : Except ValidateError Unit := do
  if hasDuplicateString (flake.inputs.map (fun input => input.fst)) then
    throw .duplicateInputNames
  else
    pure ()

  for input in flake.inputs do
    validateInput input.fst input.snd

  for system in System.all do
    validateSystemOutputs flake system

structure ValidatedFlake where
  flake : Flake
  valid : validateFlake flake = .ok ()
  carriedInvariants : List String := ["validateFlake"]

def Flake.validateChecked (flake : Flake) : Except ValidateError ValidatedFlake :=
  match h : validateFlake flake with
  | .ok _ => .ok {
      flake := flake
      valid := h
    }
  | .error error => .error error

end Leanix
