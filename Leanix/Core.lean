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
  | localSource : String -> Input
  deriving Repr, BEq

inductive BuildExpr where
  | nixpkgs : String -> BuildExpr
  | inputPath : String -> BuildExpr
  | package : String -> BuildExpr
  | runCommand : (name : String) -> (nativeBuildInputs : List BuildExpr) -> (script : String) -> BuildExpr
  deriving Repr, BEq

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
