import Leanix.Validate

namespace Leanix

def joinWith (sep : String) : List String -> String
  | [] => ""
  | item :: [] => item
  | item :: rest => item ++ sep ++ joinWith sep rest

def renderString (value : String) : String :=
  "\"" ++ value ++ "\""

def renderInputLine (input : String × Input) : Except String String := do
  match input.snd with
  | .flake pin => pure s!"    {input.fst}.url = {renderString pin.url};"
  | .localSource path =>
      pure <| "    " ++ input.fst ++ " = { url = " ++ renderString path ++ "; flake = false; };"
  | .source _ => throw "the renderer does not support hashed source inputs yet"

def renderOutputArg (inputName : String) : String :=
  if inputName == "nixpkgs" then
    "nixpkgs"
  else
    inputName

def renderBuildExprWithFuel : Nat -> BuildExpr -> String
  | 0, _ => "throw \"Leanix render depth exceeded\""
  | _ + 1, .nixpkgs attr => "pkgs." ++ attr
  | _ + 1, .inputPath name => name
  | fuel + 1, .runCommand name nativeBuildInputs script =>
      "pkgs.runCommand " ++ renderString name ++
        " { nativeBuildInputs = [ " ++
        joinWith " " (nativeBuildInputs.map (renderBuildExprListItemWithFuel fuel)) ++
        " ]; } ''\n          " ++ script ++ "\n        ''"

where
  renderBuildExprListItemWithFuel : Nat -> BuildExpr -> String
    | fuel, .runCommand name nativeBuildInputs script =>
        "(" ++ renderBuildExprWithFuel fuel (.runCommand name nativeBuildInputs script) ++ ")"
    | fuel, expr => renderBuildExprWithFuel fuel expr

def renderBuildExpr (expr : BuildExpr) : String :=
  renderBuildExprWithFuel 64 expr

def renderBuildExprListItem (expr : BuildExpr) : String :=
  match expr with
  | .runCommand _ _ _ => "(" ++ renderBuildExpr expr ++ ")"
  | _ => renderBuildExpr expr

def hasOutputs (flake : Flake) (system : System) : Bool :=
  !(flake.outputs.packages system).isEmpty ||
  !(flake.outputs.apps system).isEmpty ||
  !(flake.outputs.devShells system).isEmpty ||
  !(flake.outputs.checks system).isEmpty

def activeSystems (flake : Flake) : List System :=
  System.all.filter (fun system => hasOutputs flake system)

def findPackage? (packages : List (Package system)) (name : String) : Option (Package system) :=
  packages.find? (fun package => package.name == name)

def renderAttrSet (family : String) (entries : List String) : List String :=
  match entries with
  | [] => []
  | _ => ["      " ++ family ++ ".${system} = {"] ++ entries ++ ["      };"]

def renderPackageEntry (package : Package system) : String :=
  "        " ++ package.name ++ " = " ++ renderBuildExpr package.build ++ ";"

def renderPackageDefaults (packages : List (Package system)) : List String :=
  match packages with
  | [] => []
  | package :: _ =>
      ["        default = " ++ renderBuildExpr package.build ++ ";"]

def renderAppLine (system : System) (packages : List (Package system)) (app : App system) :
    Except String String := do
  match findPackage? packages app.packageName with
  | none => throw s!"app {app.name} refers to missing package {app.packageName}"
  | some package =>
      pure <| "        " ++ app.name ++
        " = { type = \"app\"; program = \"${" ++ renderBuildExpr package.build ++ "}/" ++
        app.program ++ "\"; };"

def renderAppDefaults (apps : List (App system)) : List String :=
  match apps with
  | [] => []
  | app :: _ =>
      ["        default = self.apps.${system}." ++ app.name ++ ";"]

def renderShellLine (system : System) (packages : List (Package system)) (shell : DevShell system) :
    Except String String := do
  let packageExprs ← shell.packageNames.mapM fun packageName =>
    match findPackage? packages packageName with
    | none => throw s!"devShell {shell.name} refers to missing package {packageName}"
    | some package => pure (renderBuildExprListItem package.build)
  pure <| "        " ++ shell.name ++
    " = pkgs.mkShell { packages = [ " ++ joinWith " " packageExprs ++ " ]; };"

def renderCheckLine (system : System) (packages : List (Package system)) (check : Check system) :
    Except String String := do
  match findPackage? packages check.packageName with
  | none => throw s!"check {check.name} refers to missing package {check.packageName}"
  | some package =>
      pure <| "        " ++ check.name ++
        " = pkgs.runCommand \"" ++ check.name ++
        "-check\" { nativeBuildInputs = [ " ++ renderBuildExprListItem package.build ++
        " ]; } ''\n          " ++ check.command ++ "\n        '';"

def renderOutputsForSystem (flake : Flake) (system : System) : Except String (List String) := do
  let packages := flake.outputs.packages system
  let apps := flake.outputs.apps system
  let devShells := flake.outputs.devShells system
  let checks := flake.outputs.checks system
  let appLines ← apps.mapM (renderAppLine system packages)
  let shellLines ← devShells.mapM (renderShellLine system packages)
  let checkLines ← checks.mapM (renderCheckLine system packages)
  pure (
    renderAttrSet "packages" (packages.map renderPackageEntry ++ renderPackageDefaults packages) ++
    renderAttrSet "apps" (appLines ++ renderAppDefaults apps) ++
    renderAttrSet "devShells" shellLines ++
    renderAttrSet "checks" checkLines
  )

def renderFlake (flake : Flake) : Except String String := do
  validateFlake flake
  let system ←
    match activeSystems flake with
    | [system] => pure system
    | [] => throw "the PoC renderer needs exactly one active system, found none"
    | _ => throw "the PoC renderer currently supports exactly one active system"
  let inputLines ← flake.inputs.mapM renderInputLine
  let outputLines ← renderOutputsForSystem flake system
  let outputArgs := ["self"] ++ flake.inputs.map (fun input => renderOutputArg input.fst)
  pure <| joinWith "\n" (
    [
      "{",
      s!"  description = {renderString flake.description};",
      "",
      "  inputs = {"
    ] ++
    inputLines ++
    [
      "  };",
      "",
      "  outputs = { " ++ joinWith ", " outputArgs ++ " }:",
      "    let",
      s!"      system = {renderString system.toNixString};",
      "      pkgs = import nixpkgs { inherit system; };",
      "    in",
      "    {"
    ] ++
    outputLines ++
    [
      "    };",
      "}",
      ""
    ]
  )

end Leanix
