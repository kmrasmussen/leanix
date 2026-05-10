import Leanix

def usage : String :=
  "usage:\n  leanix\n  leanix render-example --out generated/flake.nix\n  leanix render-closure --out generated/flake.nix\n  leanix render-self --source path:/absolute/repo --out generated/flake.nix"

def renderToFile (flake : Leanix.Flake) (outputPath : String) : IO UInt32 := do
  match Leanix.renderFlake flake with
  | .ok rendered =>
      IO.FS.createDirAll "generated"
      IO.FS.writeFile outputPath rendered
      IO.println s!"wrote {outputPath}"
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
  | ["render-invalid-missing-ref", "--out", outputPath] =>
      renderToFile Leanix.Examples.missingRefFlake outputPath
  | ["render-invalid-cycle", "--out", outputPath] =>
      renderToFile Leanix.Examples.cycleFlake outputPath
  | ["render-self", "--source", sourceUrl, "--out", outputPath] =>
      renderToFile (Leanix.Examples.selfFlakeWithSource sourceUrl) outputPath
  | _ =>
      IO.eprintln usage
      pure 1
