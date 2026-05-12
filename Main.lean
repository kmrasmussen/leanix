import Leanix

def usage : String :=
  "usage:\n  leanix\n  leanix list-examples\n  leanix render NAME --out generated/flake.nix\n  leanix render-example NAME --out generated/flake.nix\n  leanix render-example --out generated/flake.nix\n  leanix render-closure --out generated/flake.nix\n  leanix render-build-plan-text-file --out generated/flake.nix\n  leanix render-build-plan-run-executable --out generated/flake.nix\n  leanix render-cli-schema --out generated/flake.nix\n  leanix render-formatter-schema --out generated/flake.nix\n  leanix render-library-schema --out generated/flake.nix\n  leanix render-multi-app-schema --out generated/flake.nix\n  leanix render-service-schema --out generated/flake.nix\n  leanix render-showcase --out generated/flake.nix\n  leanix render-escaping --out generated/flake.nix\n  leanix render-multi-system --out generated/flake.nix\n  leanix render-multi-system-schema --out generated/flake.nix\n  leanix render-pinned-inputs --out generated/flake.nix\n  leanix render-hashed-source --source path:/absolute/source --out generated/flake.nix\n  leanix render-env --out generated/flake.nix\n  leanix render-self --source path:/absolute/repo --out generated/flake.nix\n  leanix emit-artifact --out generated/showcase-artifact\n  leanix emit-showcase-artifact --out generated/showcase-artifact\n  leanix emit-raw-check-artifact --out generated/raw-check-artifact\n  leanix verify-artifact DIR\n  leanix render-invalid-library-schema --out generated/flake.nix\n  leanix render-invalid-formatter-schema --out generated/flake.nix\n  leanix render-invalid-multi-app-schema --out generated/flake.nix\n  leanix render-invalid-service-schema --out generated/flake.nix\n  leanix render-invalid-build-plan-ref --out generated/flake.nix\n  leanix render-invalid-build-plan-input-ref --out generated/flake.nix\n  leanix render-invalid-build-plan-args --out generated/flake.nix\n  leanix render-invalid-build-plan-run-executable-ref --out generated/flake.nix\n  leanix render-invalid-lean-package-input-ref --out generated/flake.nix\n  leanix render-invalid-typed-text-ref --out generated/flake.nix\n  leanix render-invalid-typed-check-ref --out generated/flake.nix\n  leanix render-invalid-duplicate-package-env --out generated/flake.nix\n  leanix render-invalid-duplicate-shell-env --out generated/flake.nix\n  leanix render-invalid-unsupported-env-builder --out generated/flake.nix\n  leanix render-invalid-multi-system-schema --out generated/flake.nix\n  leanix render-invalid-source-missing-hash --out generated/flake.nix"

partial def startsWithChars : List Char -> List Char -> Bool
  | [], _ => true
  | _ :: _, [] => false
  | needle :: needleRest, value :: valueRest =>
      needle == value && startsWithChars needleRest valueRest

partial def containsChars (needle : List Char) : List Char -> Bool
  | [] => needle.isEmpty
  | chars@(_ :: rest) =>
      startsWithChars needle chars || containsChars needle rest

def stringContains (haystack needle : String) : Bool :=
  if needle.toList.isEmpty then
    true
  else
    containsChars needle.toList haystack.toList

def requireSubstring (context haystack needle : String) : Except String Unit :=
  if stringContains haystack needle then
    .ok ()
  else
    .error s!"{context} missing {needle}"

def firstError : List (Except String Unit) -> Option String
  | [] => none
  | .ok _ :: rest => firstError rest
  | .error error :: _ => some error

def readFileExcept (path : System.FilePath) : IO (Except String String) := do
  try
    pure (.ok (← IO.FS.readFile path))
  catch error =>
    pure (.error s!"failed reading {path}: {error}")

def dropTrailingComma (value : String) : String :=
  match value.toList.reverse with
  | ',' :: rest => String.ofList rest.reverse
  | _ => value

def parseSimpleJsonString? (value : String) : Option String :=
  match value.toList with
  | '"' :: rest =>
      match rest.reverse with
      | '"' :: body => some (String.ofList body.reverse)
      | _ => none
  | _ => none

def isJsonWhitespace : Char -> Bool
  | ' ' => true
  | '\t' => true
  | '\r' => true
  | _ => false

def dropLeadingJsonWhitespace : List Char -> List Char
  | [] => []
  | char :: rest =>
      if isJsonWhitespace char then
        dropLeadingJsonWhitespace rest
      else
        char :: rest

def trimJsonLine (value : String) : String :=
  String.ofList <|
    dropLeadingJsonWhitespace (dropLeadingJsonWhitespace value.toList |>.reverse) |>.reverse

partial def collectStringArrayLines (field : String) :
    List String -> Bool -> List String -> Option (List String)
  | [], true, _ => none
  | [], false, _ => none
  | line :: rest, false, acc =>
      if trimJsonLine line == Leanix.jsonString field ++ ": [" then
        collectStringArrayLines field rest true acc
      else
        collectStringArrayLines field rest false acc
  | line :: rest, true, acc =>
      let trimmed := trimJsonLine line
      if trimmed == "]" || trimmed == "]," then
        some acc.reverse
      else
        match parseSimpleJsonString? (dropTrailingComma trimmed) with
        | some value => collectStringArrayLines field rest true (value :: acc)
        | none => none

def extractStringArray (field manifest : String) : Except String (List String) :=
  match collectStringArrayLines field (manifest.splitOn "\n") false [] with
  | some values => .ok values
  | none => .error s!"manifest field {field} is missing or malformed"

def parseHashEntry? (entry : String) : Option (String × String) :=
  match Leanix.splitOnChar ' ' entry with
  | path :: hashParts =>
      match hashParts with
      | [] => none
      | _ => some (path, Leanix.joinWith " " hashParts)
  | _ => none

def verifyGeneratedFilesExist (dir : System.FilePath) (manifest : String) :
    IO (Except String Unit) := do
  match extractStringArray "generatedFiles" manifest with
  | .error error => pure (.error error)
  | .ok files => do
      for file in files do
        match ← readFileExcept (dir / file) with
        | .ok _ => pure ()
        | .error _ => return .error s!"generated file missing: {file}"
      pure (.ok ())

def verifyFileHashes (dir : System.FilePath) (manifest : String) :
    IO (Except String Unit) := do
  match extractStringArray "fileHashes" manifest with
  | .error error => pure (.error error)
  | .ok entries => do
      for entry in entries do
        match parseHashEntry? entry with
        | none => return .error s!"manifest file hash entry is malformed: {entry}"
        | some (file, expectedHash) =>
            match ← readFileExcept (dir / file) with
            | .error _ => return .error s!"generated file missing: {file}"
            | .ok content =>
                let actualHash := Leanix.contentHash content
                if actualHash == expectedHash then
                  pure ()
                else
                  return .error s!"artifact file hash mismatch: {file}"
      pure (.ok ())

def hasLockfileWitnessMetadata (manifest : String) : Bool :=
  stringContains manifest "\"lockfile\"" &&
  stringContains manifest "\"lockfileNode\"" &&
  stringContains manifest "\"lockedRev\"" &&
  stringContains manifest "\"lockedNarHash\""

def verifyArtifactInputPolicy (manifest : String) : Except String Unit :=
  if stringContains manifest "\"trustClass\": \"floating-flake-input\"" then
    .error "artifact input policy rejected: floating flake inputs require a pinned ref or lockfile witness"
  else if stringContains manifest "\"trustClass\": \"lockfile-backed-flake-input\"" &&
      !hasLockfileWitnessMetadata manifest then
    .error "artifact input policy rejected: lockfile-backed flake inputs require lockfile witness metadata"
  else
    .ok ()

def runReplayCommand (cwd? : Option System.FilePath) (cmd : String) (args : Array String) :
    IO (Except String Unit) := do
  let output ← IO.Process.output {
    cmd := cmd
    args := args
    cwd := cwd?
  }
  if output.exitCode == 0 then
    pure (.ok ())
  else
    pure (.error s!"replay command failed: {cmd} {Leanix.joinWith " " args.toList}\n{output.stderr}")

def verifyShowcaseArtifact (artifactDir : String) : IO (Except String Unit) := do
  let dir := System.FilePath.mk artifactDir
  let manifestPath := dir / "leanix.manifest.json"
  let flakePath := dir / "flake.nix"
  let manifest ← readFileExcept manifestPath
  match manifest with
  | .error error => pure (.error error)
  | .ok manifest => do
      match verifyArtifactInputPolicy manifest with
      | .error error => pure (.error error)
      | .ok _ => do
        match ← verifyGeneratedFilesExist dir manifest with
        | .error error => pure (.error error)
        | .ok _ => do
            match ← verifyFileHashes dir manifest with
            | .error error => pure (.error error)
            | .ok _ => do
                let flake ← readFileExcept flakePath
                match flake with
                | .error error => pure (.error error)
                | .ok flake =>
                    let inputPolicyChecks : List (Except String Unit) :=
                      if stringContains manifest "\"trustClass\": \"lockfile-backed-flake-input\"" then
                        [
                          requireSubstring "manifest input trust class" manifest "\"trustClass\": \"lockfile-backed-flake-input\"",
                          requireSubstring "manifest input pin policy" manifest "\"pinPolicy\": \"lockfile-witness\"",
                          requireSubstring "manifest lockfile witness" manifest "\"lockfile\"",
                          requireSubstring "manifest lockfile witness" manifest "\"lockfileNode\"",
                          requireSubstring "manifest lockfile witness" manifest "\"lockedRev\"",
                          requireSubstring "manifest lockfile witness" manifest "\"lockedNarHash\""
                        ]
                      else
                        [
                          requireSubstring "manifest input trust class" manifest "\"trustClass\": \"pinned-flake-input\"",
                          requireSubstring "manifest input pin policy" manifest "\"pinPolicy\": \"pinned-ref\"",
                          requireSubstring "manifest input rev" manifest "\"rev\"",
                          requireSubstring "manifest input narHash" manifest "\"narHash\""
                        ]
                    let checks : List (Except String Unit) := [
                      requireSubstring "manifest" manifest "\"generatedFiles\"",
                      requireSubstring "manifest" manifest "\"fileHashes\"",
                      requireSubstring "manifest generated files" manifest "\"flake.nix\"",
                      requireSubstring "manifest generated files" manifest "\"leanix.manifest.json\"",
                      requireSubstring "manifest systems" manifest "\"x86_64-linux\"",
                      requireSubstring "manifest packages" manifest "\"helloWrapper\"",
                      requireSubstring "manifest packages" manifest "\"helloTool\"",
                      requireSubstring "manifest apps/checks" manifest "\"packageName\": \"helloWrapper\"",
                      requireSubstring "manifest escape policy" manifest "\"escapePolicy\": \"strict-artifact\"",
                      requireSubstring "manifest checked invariants" manifest "\"PackageClosure.refsResolve\"",
                      requireSubstring "manifest checked invariants" manifest "\"PackageClosure.acyclicByFuel\"",
                      requireSubstring "manifest checked invariants" manifest "\"CliProject.appPointsAtPackage\"",
                      requireSubstring "manifest checked invariants" manifest "\"sourceTrust.fetchLikeSourcesRequireHash\"",
                      requireSubstring "artifact flake packages" flake "\"helloWrapper\" =",
                      requireSubstring "artifact flake packages" flake "\"helloTool\" =",
                      requireSubstring "artifact flake default package" flake
                        "\"default\" = self.packages.${system}.\"helloWrapper\";",
                      requireSubstring "artifact flake check" flake "\"default\" = pkgs.runCommand"
                    ] ++ inputPolicyChecks
                    match firstError checks with
                    | some error => pure (.error error)
                    | none => do
                        match ← runReplayCommand none "lake" #["env", "lean", "examples/proof-carrying-cli-closure/source.lean"] with
                        | .error error => pure (.error error)
                        | .ok _ =>
                            match ← runReplayCommand (some dir) "nix" #["flake", "check", "path:."] with
                            | .error error => pure (.error error)
                            | .ok _ => pure (.ok ())

def renderValidatedToFile (validated : Leanix.ValidatedFlake) (outputPath : String) : IO UInt32 := do
  match Leanix.renderFlake validated with
  | .ok rendered =>
      IO.FS.createDirAll "generated"
      IO.FS.writeFile outputPath rendered
      IO.println s!"wrote {outputPath}"
      pure 0
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def renderToFile (flake : Leanix.Flake) (outputPath : String) : IO UInt32 := do
  match Leanix.Flake.validateChecked flake with
  | .ok validated => renderValidatedToFile validated outputPath
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def renderExceptToFile {error : Type} [ToString error] (flake : Except error Leanix.ValidatedFlake)
    (outputPath : String) : IO UInt32 := do
  match flake with
  | .ok value => renderValidatedToFile value outputPath
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def exampleNames : List String := [
  "hello",
  "closure",
  "build-plan-text-file",
  "build-plan-run-executable",
  "cli-schema",
  "formatter-schema",
  "library-schema",
  "multi-app-schema",
  "service-schema",
  "showcase",
  "escaping",
  "multi-system",
  "multi-system-schema",
  "pinned-inputs",
  "hashed-source",
  "env",
  "self"
]

def printExampleNames : List String -> IO Unit
  | [] => pure ()
  | name :: rest => do
      IO.println name
      printExampleNames rest

def listExamples : IO UInt32 := do
  printExampleNames exampleNames
  pure 0

def renderRegisteredExample (name outputPath : String) : IO UInt32 := do
  match name with
  | "hello" => renderToFile Leanix.Examples.helloFlake outputPath
  | "closure" => renderToFile Leanix.Examples.closureFlake outputPath
  | "build-plan-text-file" => renderToFile Leanix.Examples.plannedTextFileFlake outputPath
  | "build-plan-run-executable" => renderToFile Leanix.Examples.runExecutableFlake outputPath
  | "cli-schema" => renderExceptToFile Leanix.Examples.helloCliSchemaFlake outputPath
  | "formatter-schema" => renderExceptToFile Leanix.Examples.formatterSchemaFlake outputPath
  | "library-schema" => renderExceptToFile Leanix.Examples.librarySchemaFlake outputPath
  | "multi-app-schema" => renderExceptToFile Leanix.Examples.multiAppSchemaFlake outputPath
  | "service-schema" => renderExceptToFile Leanix.Examples.serviceSchemaFlake outputPath
  | "showcase" => renderExceptToFile Leanix.Examples.showcaseFlake outputPath
  | "escaping" => renderToFile Leanix.Examples.escapingFlake outputPath
  | "multi-system" => renderToFile Leanix.Examples.multiSystemFlake outputPath
  | "multi-system-schema" => renderExceptToFile Leanix.Examples.multiSystemSchemaFlake outputPath
  | "pinned-inputs" => renderToFile Leanix.Examples.pinnedInputFlake outputPath
  | "hashed-source" =>
      renderToFile (Leanix.Examples.sourceFixtureFlakeWithSource "path:./e2e/source-fixture")
        outputPath
  | "env" => renderToFile Leanix.Examples.envFlake outputPath
  | "self" => renderToFile (Leanix.Examples.selfFlakeWithSource "path:.") outputPath
  | _ =>
      IO.eprintln s!"error: unknown example {name}"
      pure 1

def emitShowcaseArtifact (outputDir : String) : IO UInt32 := do
  match Leanix.renderShowcaseArtifact with
  | .ok (renderedFlake, manifest) =>
      IO.FS.createDirAll outputDir
      IO.FS.writeFile (System.FilePath.mk outputDir / "flake.nix") renderedFlake
      IO.FS.writeFile (System.FilePath.mk outputDir / "leanix.manifest.json") manifest
      IO.println s!"wrote {outputDir}"
      pure 0
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def emitRawCheckArtifact (outputDir : String) : IO UInt32 := do
  match Leanix.renderRawCheckArtifact with
  | .ok (renderedFlake, manifest) =>
      IO.FS.createDirAll outputDir
      IO.FS.writeFile (System.FilePath.mk outputDir / "flake.nix") renderedFlake
      IO.FS.writeFile (System.FilePath.mk outputDir / "leanix.manifest.json") manifest
      IO.println s!"wrote {outputDir}"
      pure 0
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def verifyArtifact (artifactDir : String) : IO UInt32 := do
  match ← verifyShowcaseArtifact artifactDir with
  | .ok _ =>
      IO.println s!"verified {artifactDir}"
      pure 0
  | .error error =>
      IO.eprintln s!"error: {error}"
      pure 1

def main (args : List String) : IO UInt32 := do
  match args with
  | [] =>
      IO.println "leanix: Nix flakes as Lean-checked build graphs"
      pure 0
  | ["list-examples"] =>
      listExamples
  | ["render", name, "--out", outputPath] =>
      renderRegisteredExample name outputPath
  | ["render-example", name, "--out", outputPath] =>
      renderRegisteredExample name outputPath
  | ["render-example", "--out", outputPath] =>
      renderToFile Leanix.Examples.helloFlake outputPath
  | ["render-closure", "--out", outputPath] =>
      renderToFile Leanix.Examples.closureFlake outputPath
  | ["render-build-plan-text-file", "--out", outputPath] =>
      renderToFile Leanix.Examples.plannedTextFileFlake outputPath
  | ["render-build-plan-run-executable", "--out", outputPath] =>
      renderToFile Leanix.Examples.runExecutableFlake outputPath
  | ["render-cli-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.helloCliSchemaFlake outputPath
  | ["render-formatter-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.formatterSchemaFlake outputPath
  | ["render-library-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.librarySchemaFlake outputPath
  | ["render-multi-app-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.multiAppSchemaFlake outputPath
  | ["render-service-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.serviceSchemaFlake outputPath
  | ["render-showcase", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.showcaseFlake outputPath
  | ["render-escaping", "--out", outputPath] =>
      renderToFile Leanix.Examples.escapingFlake outputPath
  | ["render-multi-system", "--out", outputPath] =>
      renderToFile Leanix.Examples.multiSystemFlake outputPath
  | ["render-multi-system-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.multiSystemSchemaFlake outputPath
  | ["render-pinned-inputs", "--out", outputPath] =>
      renderToFile Leanix.Examples.pinnedInputFlake outputPath
  | ["render-hashed-source", "--source", sourceUrl, "--out", outputPath] =>
      renderToFile (Leanix.Examples.sourceFixtureFlakeWithSource sourceUrl) outputPath
  | ["render-env", "--out", outputPath] =>
      renderToFile Leanix.Examples.envFlake outputPath
  | ["render-invalid-cli-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenCliSchemaFlake outputPath
  | ["render-invalid-library-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenLibrarySchemaFlake outputPath
  | ["render-invalid-formatter-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenFormatterSchemaFlake outputPath
  | ["render-invalid-multi-app-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenMultiAppSchemaFlake outputPath
  | ["render-invalid-service-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenServiceSchemaFlake outputPath
  | ["render-invalid-build-plan-ref", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenBuildPlanFlake outputPath
  | ["render-invalid-build-plan-input-ref", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.missingInputBuildPlanFlake outputPath
  | ["render-invalid-build-plan-args", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.duplicateBuildPlanArgumentsFlake outputPath
  | ["render-invalid-build-plan-run-executable-ref", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.missingRunExecutablePlanFlake outputPath
  | ["render-invalid-lean-package-input-ref", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.missingLeanPackageInputPlanFlake outputPath
  | ["render-invalid-missing-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.missingRefFlake outputPath
  | ["render-invalid-cycle", "--out", outputPath] =>
      renderToFile Leanix.Examples.cycleFlake outputPath
  | ["render-invalid-typed-text-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.typedTextMissingRefFlake outputPath
  | ["render-invalid-typed-check-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.typedCheckMissingRefFlake outputPath
  | ["render-invalid-duplicate-package-env", "--out", outputPath] =>
      renderToFile Leanix.Examples.duplicatePackageEnvFlake outputPath
  | ["render-invalid-duplicate-shell-env", "--out", outputPath] =>
      renderToFile Leanix.Examples.duplicateShellEnvFlake outputPath
  | ["render-invalid-unsupported-env-builder", "--out", outputPath] =>
      renderToFile Leanix.Examples.unsupportedEnvFlake outputPath
  | ["render-invalid-multi-system-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenMultiSystemSchemaFlake outputPath
  | ["render-invalid-source-missing-hash", "--out", outputPath] =>
      renderToFile Leanix.Examples.unhashedSourceFlake outputPath
  | ["render-self", "--source", sourceUrl, "--out", outputPath] =>
      renderToFile (Leanix.Examples.selfFlakeWithSource sourceUrl) outputPath
  | ["emit-artifact", "--out", outputDir] =>
      emitShowcaseArtifact outputDir
  | ["emit-showcase-artifact", "--out", outputDir] =>
      emitShowcaseArtifact outputDir
  | ["emit-raw-check-artifact", "--out", outputDir] =>
      emitRawCheckArtifact outputDir
  | ["verify-artifact", artifactDir] =>
      verifyArtifact artifactDir
  | _ =>
      IO.eprintln usage
      pure 1
