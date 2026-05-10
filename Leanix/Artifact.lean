import Leanix.Render
import Leanix.Examples

namespace Leanix

structure ArtifactInput where
  name : String
  trustClass : String
  url : String
  deriving Repr, BEq

structure ArtifactPackage where
  name : String
  builder : String
  deriving Repr, BEq

structure ArtifactReference where
  name : String
  packageName : String
  deriving Repr, BEq

structure ArtifactManifest where
  formatVersion : Nat
  rendererVersion : String
  sourceRef : String
  generatedFiles : List String
  systems : List System
  inputs : List ArtifactInput
  packages : List ArtifactPackage
  apps : List ArtifactReference
  checks : List ArtifactReference
  checkedInvariants : List String
  replayCommands : List String
  deriving Repr, BEq

def jsonEscapeChar : Char -> String
  | '"' => "\\\""
  | '\\' => "\\\\"
  | '\n' => "\\n"
  | '\r' => "\\r"
  | '\t' => "\\t"
  | c => c.toString

def jsonString (value : String) : String :=
  "\"" ++ (value.toList.map jsonEscapeChar).foldl (· ++ ·) "" ++ "\""

def indentLines (pad : String) (lines : List String) : List String :=
  lines.map (fun line => pad ++ line)

def jsonStringArrayItems : List String -> List String
  | [] => []
  | value :: [] => ["  " ++ jsonString value]
  | value :: rest => ("  " ++ jsonString value ++ ",") :: jsonStringArrayItems rest

def jsonStringArray (values : List String) : List String :=
  match values with
  | [] => ["[]"]
  | _ => ["["] ++ jsonStringArrayItems values ++ ["]"]

def jsonObjectLines (objectLines : List String) : List String :=
  ["{"] ++ indentLines "  " objectLines ++ ["}"]

def jsonObjectArrayItems : List (List String) -> List String
  | [] => []
  | object :: [] => indentLines "  " (jsonObjectLines object)
  | object :: rest =>
      let rendered := jsonObjectLines object
      let withComma :=
        match rendered.reverse with
        | [] => []
        | last :: before => (last ++ ",") :: before
      indentLines "  " withComma.reverse ++ jsonObjectArrayItems rest

def jsonObjectArray (objects : List (List String)) : List String :=
  match objects with
  | [] => ["[]"]
  | _ => ["["] ++ jsonObjectArrayItems objects ++ ["]"]

def ArtifactInput.toJsonLines (input : ArtifactInput) : List String := [
  "\"name\": " ++ jsonString input.name ++ ",",
  "\"trustClass\": " ++ jsonString input.trustClass ++ ",",
  "\"url\": " ++ jsonString input.url
]

def ArtifactPackage.toJsonLines (package : ArtifactPackage) : List String := [
  "\"name\": " ++ jsonString package.name ++ ",",
  "\"builder\": " ++ jsonString package.builder
]

def ArtifactReference.toJsonLines (reference : ArtifactReference) : List String := [
  "\"name\": " ++ jsonString reference.name ++ ",",
  "\"packageName\": " ++ jsonString reference.packageName
]

def jsonField (name : String) (value : String) : String :=
  jsonString name ++ ": " ++ value

def jsonArrayField (name : String) (lines : List String) (comma : Bool) : List String :=
  match lines with
  | [] => []
  | first :: rest =>
      let suffix := if comma then "," else ""
      let rendered := (jsonString name ++ ": " ++ first) :: rest
      match rendered.reverse with
      | [] => []
      | last :: before => ((last ++ suffix) :: before).reverse

def ArtifactManifest.toJson (manifest : ArtifactManifest) : String :=
  joinWith "\n" <| [
    "{",
    "  " ++ jsonField "formatVersion" (toString manifest.formatVersion) ++ ",",
    "  " ++ jsonField "rendererVersion" (jsonString manifest.rendererVersion) ++ ",",
    "  " ++ jsonField "sourceRef" (jsonString manifest.sourceRef) ++ ","
  ] ++
  indentLines "  " (jsonArrayField "generatedFiles" (jsonStringArray manifest.generatedFiles) true) ++
  indentLines "  " (jsonArrayField "systems" (jsonStringArray (manifest.systems.map System.toNixString)) true) ++
  indentLines "  " (jsonArrayField "inputs" (jsonObjectArray (manifest.inputs.map ArtifactInput.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "packages" (jsonObjectArray (manifest.packages.map ArtifactPackage.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "apps" (jsonObjectArray (manifest.apps.map ArtifactReference.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "checks" (jsonObjectArray (manifest.checks.map ArtifactReference.toJsonLines)) true) ++
  indentLines "  " (jsonArrayField "checkedInvariants" (jsonStringArray manifest.checkedInvariants) true) ++
  indentLines "  " (jsonArrayField "replayCommands" (jsonStringArray manifest.replayCommands) false) ++
  [
    "}",
    ""
  ]

def buildExprKind : BuildExpr -> String
  | .nixpkgs _ => "nixpkgs"
  | .inputPath _ => "inputPath"
  | .package _ => "package"
  | .runCommand _ _ _ => "runCommand"
  | .runSteps _ _ _ => "runSteps"

def inputTrustClass : Input -> String
  | .flake _ => "lockfile-backed-flake-input"
  | .source _ => "fixed-output-source"
  | .localDevSource _ => "local-development-source"
  | .impureLocalSource _ => "impure-local-source"

def inputUrl : Input -> String
  | .flake pin => pin.url
  | .source pin => pin.url
  | .localDevSource path => path
  | .impureLocalSource path => path

def inputArtifact (input : String × Input) : ArtifactInput := {
  name := input.fst
  trustClass := inputTrustClass input.snd
  url := inputUrl input.snd
}

def packageArtifact (package : Package system) : ArtifactPackage := {
  name := package.name
  builder := buildExprKind package.build
}

def appArtifact (app : App system) : ArtifactReference := {
  name := app.name
  packageName := app.packageName
}

def checkArtifact (check : Check system) : ArtifactReference := {
  name := check.name
  packageName := check.packageName
}

def showcaseArtifactManifest : ArtifactManifest := {
  formatVersion := 1
  rendererVersion := "leanix-poc-1"
  sourceRef := "examples/proof-carrying-cli-closure/source.lean"
  generatedFiles := ["flake.nix", "leanix.manifest.json"]
  systems := [.x86_64_linux]
  inputs := [("nixpkgs", Examples.nixpkgsInput)].map inputArtifact
  packages := (Examples.showcaseCliProject.package :: Examples.showcaseCliProject.extraPackages).map packageArtifact
  apps := [Examples.showcaseCliProject.app].map appArtifact
  checks := [Examples.showcaseCliProject.check].map checkArtifact
  checkedInvariants := [
    "validateFlake.uniqueInputNames",
    "validateFlake.uniqueOutputNames",
    "validateFlake.packageReferencesResolve",
    "PackageClosure.refsResolve",
    "PackageClosure.acyclicByFuel",
    "CliProject.defaultOutputNames",
    "CliProject.appPointsAtPackage",
    "CliProject.checkPointsAtPackage",
    "CliProject.devShellContainsPackage",
    "sourceTrust.fetchLikeSourcesRequireHash"
  ]
  replayCommands := [
    "lake env lean examples/proof-carrying-cli-closure/source.lean",
    "nix flake check path:."
  ]
}

def renderShowcaseArtifact : Except String (String × String) := do
  let validatedFlake ←
    match Examples.showcaseFlake with
    | .ok validatedFlake => pure validatedFlake
    | .error error => throw error
  let renderedFlake ← renderFlake validatedFlake
  pure (renderedFlake, showcaseArtifactManifest.toJson)

end Leanix
