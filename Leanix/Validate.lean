import Leanix.Core

namespace Leanix

def hasDuplicateString : List String -> Bool
  | [] => false
  | name :: rest => rest.contains name || hasDuplicateString rest

def validateUniqueNames (system : System) (family : String) (names : List String) :
    Except String Unit := do
  if hasDuplicateString names then
    throw s!"duplicate {family} names for {system.toNixString}"
  else
    pure ()

def validatePackageRef (system : System) (packageNames : List String) (owner : String)
    (packageName : String) : Except String Unit := do
  if packageNames.contains packageName then
    pure ()
  else
    throw s!"{owner} for {system.toNixString} refers to missing package {packageName}"

def validateBuildExprInputRefs (inputNames : List String) : BuildExpr -> Except String Unit
  | .nixpkgs _ => pure ()
  | .inputPath name =>
      if inputNames.contains name then
        pure ()
      else
        throw s!"build expression refers to missing input {name}"
  | .package _ => pure ()
  | .runCommand _ nativeBuildInputs _ =>
      for input in nativeBuildInputs do
        validateBuildExprInputRefs inputNames input
  | .runSteps _ nativeBuildInputs _ =>
      for input in nativeBuildInputs do
        validateBuildExprInputRefs inputNames input

mutual
def buildExprPackageRefs : BuildExpr -> List String
  | .nixpkgs _ => []
  | .inputPath _ => []
  | .package name => [name]
  | .runCommand _ nativeBuildInputs _ =>
      buildExprPackageRefsList nativeBuildInputs
  | .runSteps _ nativeBuildInputs _ =>
      buildExprPackageRefsList nativeBuildInputs

def buildExprPackageRefsList : List BuildExpr -> List String
  | [] => []
  | input :: rest => buildExprPackageRefs input ++ buildExprPackageRefsList rest
end

def validateBuildExprPackageRefs (system : System) (packageNames : List String) (owner : String) :
    BuildExpr -> Except String Unit
  | .nixpkgs _ => pure ()
  | .inputPath _ => pure ()
  | .package name => validatePackageRef system packageNames owner name
  | .runCommand _ nativeBuildInputs _ =>
      for input in nativeBuildInputs do
        validateBuildExprPackageRefs system packageNames owner input
  | .runSteps _ nativeBuildInputs _ =>
      for input in nativeBuildInputs do
        validateBuildExprPackageRefs system packageNames owner input

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
    Except String Unit := do
  let fuel := packages.length + 1
  for package in packages do
    for dep in packageDeps package do
      if reachesPackageWithFuel packages package.name dep fuel then
        throw s!"package dependency cycle for {system.toNixString}: {package.name} reaches itself through {dep}"
      else
        pure ()

def validateSystemOutputs (flake : Flake) (system : System) : Except String Unit := do
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
    validateBuildExprPackageRefs system packageNames s!"package {package.name}" package.build

  validateNoPackageCycles system packages

  for app in apps do
    validatePackageRef system packageNames s!"app {app.name}" app.packageName

  for shell in devShells do
    for packageName in shell.packageNames do
      validatePackageRef system packageNames s!"devShell {shell.name}" packageName

  for check in checks do
    validatePackageRef system packageNames s!"check {check.name}" check.packageName

def validateInput (name : String) (input : Input) : Except String Unit := do
  match input with
  | .flake _ => pure ()
  | .localSource _ => pure ()
  | .source pin =>
      match pin.narHash? with
      | some _ => pure ()
      | none => throw s!"source input {name} must have a narHash"

def validateFlake (flake : Flake) : Except String Unit := do
  if hasDuplicateString (flake.inputs.map (fun input => input.fst)) then
    throw "duplicate input names"
  else
    pure ()

  for input in flake.inputs do
    validateInput input.fst input.snd

  for system in System.all do
    validateSystemOutputs flake system

end Leanix
