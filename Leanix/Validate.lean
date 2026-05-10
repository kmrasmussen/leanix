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
  | .runCommand _ nativeBuildInputs _ =>
      for input in nativeBuildInputs do
        validateBuildExprInputRefs inputNames input

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
