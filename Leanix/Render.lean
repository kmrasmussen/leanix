import Leanix.Validate

namespace Leanix

def joinWith (sep : String) : List String -> String
  | [] => ""
  | item :: [] => item
  | item :: rest => item ++ sep ++ joinWith sep rest

def concatLines : List (List String) -> List String
  | [] => []
  | lines :: rest => lines ++ concatLines rest

def escapeNixStringChars : List Char -> String
  | [] => ""
  | '"' :: rest => "\\\"" ++ escapeNixStringChars rest
  | '\\' :: rest => "\\\\" ++ escapeNixStringChars rest
  | '\n' :: rest => "\\n" ++ escapeNixStringChars rest
  | '\r' :: rest => "\\r" ++ escapeNixStringChars rest
  | '\t' :: rest => "\\t" ++ escapeNixStringChars rest
  | '$' :: '{' :: rest => "\\${" ++ escapeNixStringChars rest
  | c :: rest => c.toString ++ escapeNixStringChars rest

def escapeNixString (value : String) : String :=
  escapeNixStringChars value.toList

def renderString (value : String) : String :=
  "\"" ++ escapeNixString value ++ "\""

def escapeNixStringAllowInterpolationChars : List Char -> String
  | [] => ""
  | '"' :: rest => "\\\"" ++ escapeNixStringAllowInterpolationChars rest
  | '\\' :: rest => "\\\\" ++ escapeNixStringAllowInterpolationChars rest
  | '\n' :: rest => "\\n" ++ escapeNixStringAllowInterpolationChars rest
  | '\r' :: rest => "\\r" ++ escapeNixStringAllowInterpolationChars rest
  | '\t' :: rest => "\\t" ++ escapeNixStringAllowInterpolationChars rest
  | c :: rest => c.toString ++ escapeNixStringAllowInterpolationChars rest

def renderStringAllowInterpolation (value : String) : String :=
  "\"" ++ escapeNixStringAllowInterpolationChars value.toList ++ "\""

def renderAttrName (value : String) : String :=
  renderString value

def escapeNixIndentedStringChars : List Char -> String
  | [] => ""
  | '\'' :: '\'' :: rest => "'''" ++ escapeNixIndentedStringChars rest
  | '$' :: '{' :: rest => "''${" ++ escapeNixIndentedStringChars rest
  | c :: rest => c.toString ++ escapeNixIndentedStringChars rest

def escapeNixIndentedString (value : String) : String :=
  escapeNixIndentedStringChars value.toList

def HashAlgorithm.toNixString : HashAlgorithm -> String
  | .sha256 => "sha256"
  | .sha512 => "sha512"

def renderContentHash (hash : ContentHash) : String :=
  hash.algorithm.toNixString ++ "-" ++ hash.digest

def renderInputLine? (input : String × Input) : Except String (Option String) := do
  match input.snd with
  | .flake pin => pure (some s!"    {renderAttrName input.fst}.url = {renderString pin.url};")
  | .localDevSource path =>
      pure <| some <| joinWith "\n" [
        s!"    # Leanix: local development-only source.",
        "    " ++ renderAttrName input.fst ++ " = { url = " ++ renderString path ++ "; flake = false; };"
      ]
  | .impureLocalSource path =>
      pure <| some <| joinWith "\n" [
        s!"    # Leanix: impure local source.",
        "    " ++ renderAttrName input.fst ++ " = { url = " ++ renderString path ++ "; flake = false; };"
      ]
  | .source _ => pure none

def renderInputLines : List (String × Input) -> Except String (List String)
  | [] => pure []
  | input :: rest => do
      let rendered? ← renderInputLine? input
      let renderedRest ← renderInputLines rest
      match rendered? with
      | some rendered => pure (rendered :: renderedRest)
      | none => pure renderedRest

def renderSourceBinding? (input : String × Input) : Except String (Option (List String)) := do
  match input.snd with
  | .source pin =>
      match pin.narHash? with
      | some narHash =>
          pure <| some [
            "      " ++ input.fst ++ " = (builtins.fetchTree {",
            "        type = \"tarball\";",
            "        url = " ++ renderString pin.url ++ ";",
            "        narHash = " ++ renderString (renderContentHash narHash) ++ ";",
            "      }).outPath;"
          ]
      | none => throw s!"source input {input.fst} must have a narHash"
  | _ => pure none

def renderSourceBindings : List (String × Input) -> Except String (List String)
  | [] => pure []
  | input :: rest => do
      let rendered? ← renderSourceBinding? input
      let renderedRest ← renderSourceBindings rest
      match rendered? with
      | some rendered => pure (rendered ++ renderedRest)
      | none => pure renderedRest

def renderOutputArg (inputName : String) : String :=
  if inputName == "nixpkgs" then
    "nixpkgs"
  else
    inputName

def renderOutputArgs : List (String × Input) -> List String
  | [] => []
  | input :: rest =>
      match input.snd with
      | .source _ => renderOutputArgs rest
      | _ => renderOutputArg input.fst :: renderOutputArgs rest

mutual
def renderBuildExprWithFuel (system : System) : Nat -> BuildExpr -> Except String String
  | 0, _ => throw "Leanix render depth exceeded"
  | _ + 1, .nixpkgs attr => pure <| "pkgs." ++ attr
  | _ + 1, .inputPath name => pure name
  | _ + 1, .package name => pure <| "self.packages.${system}." ++ renderAttrName name
  | fuel + 1, .runCommand name nativeBuildInputs script => do
      let renderedInputs ← nativeBuildInputs.mapM (renderBuildExprListItemWithFuel system fuel)
      pure <| "pkgs.runCommand " ++ renderString name ++
        " { nativeBuildInputs = [ " ++
        joinWith " " renderedInputs ++
        " ]; } ''\n          " ++ escapeNixIndentedString script ++ "\n        ''"
  | fuel + 1, .runSteps name nativeBuildInputs steps => do
      let renderedInputs ← nativeBuildInputs.mapM (renderBuildExprListItemWithFuel system fuel)
      let renderedSteps ← renderBuildStepsWithFuel system fuel steps
      pure <| "pkgs.runCommand " ++ renderString name ++
        " { nativeBuildInputs = [ " ++
        joinWith " " renderedInputs ++
        " ]; } ''\n" ++ renderedSteps ++ "\n        ''"

def renderBuildStepWithFuel (system : System) (fuel : Nat) : BuildStep -> Except String String
  | .copySource source destination => do
      let renderedSource ← renderBuildExprListItemWithFuel system fuel source
      pure <| "          cp -R ${" ++ renderedSource ++ "} " ++
        renderString destination ++ "\n" ++
        "          chmod -R u+w " ++ renderString destination
  | .installExecutableScript path content =>
      pure <| "          install -D -m755 ${pkgs.writeText " ++ renderString "leanix-script" ++ " " ++
        renderStringAllowInterpolation content ++ "} " ++ renderString path
  | .buildLeanProject directory =>
      pure <| "          (cd " ++ renderString directory ++ " && lake build)"
  | .mkdir path => pure <| "          mkdir -p " ++ renderString path
  | .writeFile path content =>
      pure <| "          cp ${pkgs.writeText " ++ renderString "leanix-file" ++ " " ++ renderString content ++
        "} " ++ renderString path
  | .chmodExecutable path => pure <| "          chmod +x " ++ renderString path
  | .run command => pure <| "          " ++ command

def renderBuildStepsWithFuel (system : System) (fuel : Nat) (steps : List BuildStep) :
    Except String String := do
  let renderedSteps ← steps.mapM (renderBuildStepWithFuel system fuel)
  pure <| joinWith "\n" renderedSteps

def renderBuildExprListItemWithFuel (system : System) : Nat -> BuildExpr -> Except String String
  | fuel, .runCommand name nativeBuildInputs script => do
      let rendered ← renderBuildExprWithFuel system fuel (.runCommand name nativeBuildInputs script)
      pure <| "(" ++ rendered ++ ")"
  | fuel, .runSteps name nativeBuildInputs steps => do
      let rendered ← renderBuildExprWithFuel system fuel (.runSteps name nativeBuildInputs steps)
      pure <| "(" ++ rendered ++ ")"
  | fuel, expr => renderBuildExprWithFuel system fuel expr
end

def renderBuildExpr (system : System) (expr : BuildExpr) : Except String String :=
  renderBuildExprWithFuel system 64 expr

def renderBuildExprListItem (system : System) (expr : BuildExpr) : Except String String :=
  match expr with
  | .runCommand _ _ _ => do
      let rendered ← renderBuildExpr system expr
      pure <| "(" ++ rendered ++ ")"
  | .runSteps _ _ _ => do
      let rendered ← renderBuildExpr system expr
      pure <| "(" ++ rendered ++ ")"
  | _ => renderBuildExpr system expr

def hasOutputs (flake : Flake) (system : System) : Bool :=
  !(flake.outputs.packages system).isEmpty ||
  !(flake.outputs.apps system).isEmpty ||
  !(flake.outputs.devShells system).isEmpty ||
  !(flake.outputs.checks system).isEmpty

def activeSystems (flake : Flake) : List System :=
  System.all.filter (fun system => hasOutputs flake system)

def findPackage? (packages : List (Package system)) (name : String) : Option (Package system) :=
  packages.find? (fun package => package.name == name)

def renderPackageRef (packageName : String) : String :=
  "self.packages.${system}." ++ renderAttrName packageName

def renderSystemAttrSet (system : System) (family : String) (entries : List String) :
    List String :=
  match entries with
  | [] => []
  | _ => [
      "      " ++ family ++ "." ++ renderAttrName system.toNixString ++ " = let",
      s!"        system = {renderString system.toNixString};",
      "        pkgs = pkgsFor system;",
      "      in {"
    ] ++ entries ++ ["      };"]

def renderPackageEntry (system : System) (package : Package system) : Except String String := do
  let renderedBuild ← renderBuildExpr system package.build
  pure <| "        " ++ renderAttrName package.name ++ " = " ++ renderedBuild ++ ";"

def renderPackageDefaults (system : System) (packages : List (Package system)) : List String :=
  match packages with
  | [] => []
  | package :: _ =>
      if packages.any (fun package => package.name == "default") then
        []
      else
        [
          "        " ++ renderAttrName "default" ++ " = self.packages.${system}." ++
            renderAttrName package.name ++ ";"
        ]

def renderCheckedPackageGraphEntries (system : System) (graph : CheckedPackageGraph system) :
    Except String (List String) := do
  let packageEntries ← graph.packages.mapM (renderPackageEntry system)
  pure <| packageEntries ++ renderPackageDefaults system graph.packages

def renderCheckedPackageGraphAttrSet (system : System) (graph : CheckedPackageGraph system) :
    Except String (List String) := do
  let entries ← renderCheckedPackageGraphEntries system graph
  pure <| renderSystemAttrSet system "packages" entries

def renderAppLine (system : System) (packages : List (Package system)) (app : App system) :
    Except String String := do
  match findPackage? packages app.packageName with
  | none => throw s!"app {app.name} refers to missing package {app.packageName}"
  | some _ =>
      pure <| "        " ++ renderAttrName app.name ++
        " = { type = \"app\"; program = \"${" ++ renderPackageRef app.packageName ++ "}/" ++
        app.program ++ "\"; };"

def renderAppDefaults (apps : List (App system)) : List String :=
  match apps with
  | [] => []
  | app :: _ =>
      if apps.any (fun app => app.name == "default") then
        []
      else
        ["        " ++ renderAttrName "default" ++ " = self.apps.${system}." ++ renderAttrName app.name ++ ";"]

def renderShellLine (system : System) (packages : List (Package system)) (shell : DevShell system) :
    Except String String := do
  let packageExprs ← shell.packageNames.mapM fun packageName =>
    match findPackage? packages packageName with
    | none => throw s!"devShell {shell.name} refers to missing package {packageName}"
    | some _ => pure (renderPackageRef packageName)
  pure <| "        " ++ renderAttrName shell.name ++
    " = pkgs.mkShell { packages = [ " ++ joinWith " " packageExprs ++ " ]; };"

def renderCheckLine (system : System) (packages : List (Package system)) (check : Check system) :
    Except String String := do
  match findPackage? packages check.packageName with
  | none => throw s!"check {check.name} refers to missing package {check.packageName}"
  | some _ =>
      pure <| "        " ++ renderAttrName check.name ++
        " = pkgs.runCommand " ++ renderString (check.name ++ "-check") ++
        " { nativeBuildInputs = [ " ++ renderPackageRef check.packageName ++
        " ]; } ''\n          " ++ escapeNixIndentedString check.command ++ "\n        '';"

def renderOutputsForSystem (flake : Flake) (system : System) : Except String (List String) := do
  let packages := flake.outputs.packages system
  let apps := flake.outputs.apps system
  let devShells := flake.outputs.devShells system
  let checks := flake.outputs.checks system
  let packageLines ← packages.mapM (renderPackageEntry system)
  let appLines ← apps.mapM (renderAppLine system packages)
  let shellLines ← devShells.mapM (renderShellLine system packages)
  let checkLines ← checks.mapM (renderCheckLine system packages)
  pure (
    renderSystemAttrSet system "packages" (packageLines ++ renderPackageDefaults system packages) ++
    renderSystemAttrSet system "apps" (appLines ++ renderAppDefaults apps) ++
    renderSystemAttrSet system "devShells" shellLines ++
    renderSystemAttrSet system "checks" checkLines
  )

def renderFlake (validated : ValidatedFlake) : Except String String := do
  let flake := validated.flake
  let systems ←
    match activeSystems flake with
    | [] => throw "the PoC renderer needs at least one active system"
    | systems => pure systems
  let inputLines ← renderInputLines flake.inputs
  let sourceBindings ← renderSourceBindings flake.inputs
  let outputLinesBySystem ← systems.mapM (renderOutputsForSystem flake)
  let outputLines := concatLines outputLinesBySystem
  let outputArgs := ["self"] ++ renderOutputArgs flake.inputs
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
      "      pkgsFor = system: import nixpkgs { inherit system; };"
    ] ++
    sourceBindings ++
    [
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
