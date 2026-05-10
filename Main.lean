import Leanix

def usage : String :=
  "usage:\n  leanix\n  leanix render-example --out generated/flake.nix"

def main (args : List String) : IO UInt32 := do
  match args with
  | [] =>
      IO.println "leanix: Nix flakes as Lean-checked build graphs"
      pure 0
  | ["render-example", "--out", outputPath] =>
      match Leanix.renderFlake Leanix.Examples.helloFlake with
      | .ok rendered =>
          IO.FS.createDirAll "generated"
          IO.FS.writeFile outputPath rendered
          IO.println s!"wrote {outputPath}"
          pure 0
      | .error error =>
          IO.eprintln s!"error: {error}"
          pure 1
  | _ =>
      IO.eprintln usage
      pure 1
