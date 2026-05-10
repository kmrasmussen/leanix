import Leanix

def usage : String :=
  "usage:\n  leanix\n  leanix render-example --out generated/flake.nix\n  leanix render-closure --out generated/flake.nix\n  leanix render-cli-schema --out generated/flake.nix\n  leanix render-showcase --out generated/flake.nix\n  leanix render-escaping --out generated/flake.nix\n  leanix render-multi-system --out generated/flake.nix\n  leanix render-pinned-inputs --out generated/flake.nix\n  leanix render-hashed-source --source path:/absolute/source --out generated/flake.nix\n  leanix render-self --source path:/absolute/repo --out generated/flake.nix\n  leanix emit-artifact --out generated/showcase-artifact\n  leanix emit-showcase-artifact --out generated/showcase-artifact\n  leanix render-invalid-typed-text-ref --out generated/flake.nix\n  leanix render-invalid-source-missing-hash --out generated/flake.nix"

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
  | ["render-pinned-inputs", "--out", outputPath] =>
      renderToFile Leanix.Examples.pinnedInputFlake outputPath
  | ["render-hashed-source", "--source", sourceUrl, "--out", outputPath] =>
      renderToFile (Leanix.Examples.sourceFixtureFlakeWithSource sourceUrl) outputPath
  | ["render-invalid-cli-schema", "--out", outputPath] =>
      renderExceptToFile Leanix.Examples.brokenCliSchemaFlake outputPath
  | ["render-invalid-missing-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.missingRefFlake outputPath
  | ["render-invalid-cycle", "--out", outputPath] =>
      renderToFile Leanix.Examples.cycleFlake outputPath
  | ["render-invalid-typed-text-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.typedTextMissingRefFlake outputPath
  | ["render-invalid-source-missing-hash", "--out", outputPath] =>
      renderToFile Leanix.Examples.unhashedSourceFlake outputPath
  | ["render-self", "--source", sourceUrl, "--out", outputPath] =>
      renderToFile (Leanix.Examples.selfFlakeWithSource sourceUrl) outputPath
  | ["emit-artifact", "--out", outputDir] =>
      emitShowcaseArtifact outputDir
  | ["emit-showcase-artifact", "--out", outputDir] =>
      emitShowcaseArtifact outputDir
  | _ =>
      IO.eprintln usage
      pure 1
