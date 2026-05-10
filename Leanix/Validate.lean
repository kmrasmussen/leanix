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

def validatePackageRef (system : System) (packageNames : List String) (owner : String)
    (packageName : String) : Except ValidateError Unit := do
  if packageNames.contains packageName then
    pure ()
  else
    throw (.missingPackageRef system owner packageName)

mutual
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
  | .installExecutableScript _ _ => pure ()
  | .buildLeanProject _ => pure ()
  | .mkdir _ => pure ()
  | .writeFile _ _ => pure ()
  | .chmodExecutable _ => pure ()
  | .run _ => pure ()
end

mutual
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
  | .installExecutableScript _ _ => []
  | .buildLeanProject _ => []
  | .mkdir _ => []
  | .writeFile _ _ => []
  | .chmodExecutable _ => []
  | .run _ => []

def buildStepPackageRefsList : List BuildStep -> List String
  | [] => []
  | step :: rest => buildStepPackageRefs step ++ buildStepPackageRefsList rest
end

mutual
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
  | .installExecutableScript _ _ => pure ()
  | .buildLeanProject _ => pure ()
  | .mkdir _ => pure ()
  | .writeFile _ _ => pure ()
  | .chmodExecutable _ => pure ()
  | .run _ => pure ()
end

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

structure Valid (packages : List (Package system)) : Prop where
  refsResolve : refsResolveBool packages = true
  acyclicByFuel : acyclicByFuelBool packages = true

end PackageClosure

structure CheckedPackageGraph (system : System) where
  packages : List (Package system)
  valid : PackageClosure.Valid packages

def CheckedPackageGraph.refsResolve (graph : CheckedPackageGraph system) :
    PackageClosure.refsResolveBool graph.packages = true :=
  graph.valid.refsResolve

def CheckedPackageGraph.acyclicByFuel (graph : CheckedPackageGraph system) :
    PackageClosure.acyclicByFuelBool graph.packages = true :=
  graph.valid.acyclicByFuel

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
          refsResolve := hRefs
          acyclicByFuel := hAcyclic
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
  let packageNames := packages.map (fun package => package.name)
  let inputNames := flake.inputs.map (fun input => input.fst)

  validateUniqueNames system "package" packageNames
  validateUniqueNames system "app" (apps.map (fun app => app.name))
  validateUniqueNames system "devShell" (devShells.map (fun shell => shell.name))
  validateUniqueNames system "check" (checks.map (fun check => check.name))

  for package in packages do
    validateBuildExprInputRefs inputNames package.build

  let _checkedPackages ← checkPackageGraph system packages

  for app in apps do
    validatePackageRef system packageNames s!"app {app.name}" app.packageName

  for shell in devShells do
    for packageName in shell.packageNames do
      validatePackageRef system packageNames s!"devShell {shell.name}" packageName

  for check in checks do
    validatePackageRef system packageNames s!"check {check.name}" check.packageName

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
