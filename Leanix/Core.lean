namespace Leanix

inductive System where
  | x86_64_linux
  | aarch64_linux
  | x86_64_darwin
  | aarch64_darwin
  deriving Repr, BEq, DecidableEq

def System.all : List System :=
  [
    .x86_64_linux,
    .aarch64_linux,
    .x86_64_darwin,
    .aarch64_darwin
  ]

def System.toNixString : System -> String
  | .x86_64_linux => "x86_64-linux"
  | .aarch64_linux => "aarch64-linux"
  | .x86_64_darwin => "x86_64-darwin"
  | .aarch64_darwin => "aarch64-darwin"

inductive HashAlgorithm where
  | sha256
  | sha512
  deriving Repr, BEq, DecidableEq

structure ContentHash where
  algorithm : HashAlgorithm
  digest : String
  deriving Repr, BEq

structure SourcePin where
  url : String
  rev? : Option String := none
  narHash? : Option ContentHash := none
  deriving Repr, BEq

inductive Input where
  | flake : SourcePin -> Input
  | source : SourcePin -> Input
  | localDevSource : String -> Input
  | impureLocalSource : String -> Input
  deriving Repr, BEq

inductive BuildText where
  | literal : String -> BuildText
  | package : String -> BuildText
  | inputPath : String -> BuildText
  | outPath : BuildText
  | concat : List BuildText -> BuildText
  deriving Repr, BEq

mutual
inductive BuildExpr where
  | nixpkgs : String -> BuildExpr
  | inputPath : String -> BuildExpr
  | package : String -> BuildExpr
  | runCommand : (name : String) -> (nativeBuildInputs : List BuildExpr) -> (script : String) -> BuildExpr
  | runSteps : (name : String) -> (nativeBuildInputs : List BuildExpr) -> (steps : List BuildStep) -> BuildExpr
  deriving Repr, BEq

inductive BuildStep where
  | copySource : (source : BuildExpr) -> (destination : String) -> BuildStep
  | installExecutableScript : (path : String) -> (content : String) -> BuildStep
  | installExecutableTextScript : (path : String) -> (content : BuildText) -> BuildStep
  | buildLeanProject : (directory : String) -> BuildStep
  | mkdir : String -> BuildStep
  | writeFile : (path : String) -> (content : String) -> BuildStep
  | writeTextFile : (path : String) -> (content : BuildText) -> BuildStep
  | chmodExecutable : String -> BuildStep
  | run : String -> BuildStep
  deriving Repr, BEq
end

structure EnvVar where
  name : String
  value : String
  deriving Repr, BEq

structure Package (system : System) where
  name : String
  build : BuildExpr
  args : List String := []
  inputs : List Input := []
  env : List EnvVar := []
  deriving Repr, BEq

structure App (system : System) where
  name : String
  packageName : String
  program : String
  deriving Repr, BEq

structure DevShell (system : System) where
  name : String
  packageNames : List String := []
  env : List EnvVar := []
  shellHook? : Option String := none
  deriving Repr, BEq

structure Check (system : System) where
  name : String
  packageName : String
  command : String
  deriving Repr, BEq

structure Outputs where
  packages : (system : System) -> List (Package system)
  apps : (system : System) -> List (App system)
  devShells : (system : System) -> List (DevShell system)
  checks : (system : System) -> List (Check system)

def Outputs.empty : Outputs where
  packages := fun _ => []
  apps := fun _ => []
  devShells := fun _ => []
  checks := fun _ => []

structure Flake where
  description : String
  inputs : List (String × Input) := []
  outputs : Outputs := Outputs.empty

end Leanix
