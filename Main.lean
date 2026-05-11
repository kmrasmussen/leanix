import Leanix

def usage : String :=
  "usage:\n  leanix\n  leanix render-example --out generated/flake.nix\n  leanix render-closure --out generated/flake.nix\n  leanix render-cli-schema --out generated/flake.nix\n  leanix render-showcase --out generated/flake.nix\n  leanix render-escaping --out generated/flake.nix\n  leanix render-multi-system --out generated/flake.nix\n  leanix render-multi-system-schema --out generated/flake.nix\n  leanix render-pinned-inputs --out generated/flake.nix\n  leanix render-hashed-source --source path:/absolute/source --out generated/flake.nix\n  leanix render-env --out generated/flake.nix\n  leanix render-self --source path:/absolute/repo --out generated/flake.nix\n  leanix emit-artifact --out generated/showcase-artifact\n  leanix emit-showcase-artifact --out generated/showcase-artifact\n  leanix verify-artifact DIR\n  leanix render-invalid-typed-text-ref --out generated/flake.nix\n  leanix render-invalid-duplicate-package-env --out generated/flake.nix\n  leanix render-invalid-duplicate-shell-env --out generated/flake.nix\n  leanix render-invalid-unsupported-env-builder --out generated/flake.nix\n  leanix render-invalid-multi-system-schema --out generated/flake.nix\n  leanix render-invalid-source-missing-hash --out generated/flake.nix"

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
  let flake ← readFileExcept flakePath
  match manifest, flake with
  | .error error, _ => pure (.error error)
  | _, .error error => pure (.error error)
  | .ok manifest, .ok flake => do
      let checks : List (Except String Unit) := [
        requireSubstring "manifest" manifest "\"generatedFiles\"",
        requireSubstring "manifest generated files" manifest "\"flake.nix\"",
        requireSubstring "manifest generated files" manifest "\"leanix.manifest.json\"",
        requireSubstring "manifest systems" manifest "\"x86_64-linux\"",
        requireSubstring "manifest packages" manifest "\"helloWrapper\"",
        requireSubstring "manifest packages" manifest "\"helloTool\"",
        requireSubstring "manifest apps/checks" manifest "\"packageName\": \"helloWrapper\"",
        requireSubstring "manifest checked invariants" manifest "\"PackageClosure.refsResolve\"",
        requireSubstring "manifest checked invariants" manifest "\"PackageClosure.acyclicByFuel\"",
        requireSubstring "manifest checked invariants" manifest "\"CliProject.appPointsAtPackage\"",
        requireSubstring "manifest checked invariants" manifest "\"sourceTrust.fetchLikeSourcesRequireHash\"",
        requireSubstring "artifact flake packages" flake "\"helloWrapper\" =",
        requireSubstring "artifact flake packages" flake "\"helloTool\" =",
        requireSubstring "artifact flake default package" flake
          "\"default\" = self.packages.${system}.\"helloWrapper\";",
        requireSubstring "artifact flake check" flake "\"default\" = pkgs.runCommand"
      ]
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
  | ["render-example", "--out", outputPath] =>
      renderToFile Leanix.Examples.helloFlake outputPath
  | ["render-closure", "--out", outputPath] =>
      renderToFile Leanix.Examples.closureFlake outputPath
  | ["render-cli-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.helloCliSchemaFlake outputPath
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
  | ["render-invalid-missing-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.missingRefFlake outputPath
  | ["render-invalid-cycle", "--out", outputPath] =>
      renderToFile Leanix.Examples.cycleFlake outputPath
  | ["render-invalid-typed-text-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.typedTextMissingRefFlake outputPath
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
  | ["verify-artifact", artifactDir] =>
      verifyArtifact artifactDir
  | _ =>
      IO.eprintln usage
      pure 1
