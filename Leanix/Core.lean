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
  | installTextFile : (path : String) -> (content : BuildText) -> BuildStep
  | installExecutableScript : (path : String) -> (content : String) -> BuildStep
  | installExecutableTextScript : (path : String) -> (content : BuildText) -> BuildStep
  | buildLeanProject : (directory : String) -> BuildStep
  | mkdir : String -> BuildStep
  | copyFile : (source : String) -> (destination : String) -> BuildStep
  | writeFile : (path : String) -> (content : String) -> BuildStep
  | writeTextFile : (path : String) -> (content : BuildText) -> BuildStep
  | chmodExecutable : String -> BuildStep
  | run : String -> BuildStep
  deriving Repr, BEq
end

inductive KnownNixpkgsPackage where
  | hello
  | lean4
  deriving Repr, BEq, DecidableEq

def KnownNixpkgsPackage.toAttr : KnownNixpkgsPackage -> String
  | .hello => "hello"
  | .lean4 => "lean4"

structure ExecutableWrapperArgs where
  derivationName : String
  packageName : String
  executablePath : String
  arguments : List String := []
  destination : String
  deriving Repr, BEq

structure CopyInputTreeArgs where
  derivationName : String
  inputName : String
  destination : String
  deriving Repr, BEq

structure CopyInputFileArgs where
  derivationName : String
  inputName : String
  sourcePath : String
  destination : String
  deriving Repr, BEq

structure InstallTextFileArgs where
  derivationName : String
  destination : String
  content : BuildText
  deriving Repr, BEq

inductive BuildPlan where
  | nixpkgsPackage : KnownNixpkgsPackage -> BuildPlan
  | executableTextWrapper : ExecutableWrapperArgs -> BuildPlan
  | copyInputTree : CopyInputTreeArgs -> BuildPlan
  | copyInputFile : CopyInputFileArgs -> BuildPlan
  | installTextFile : InstallTextFileArgs -> BuildPlan
  deriving Repr, BEq

namespace BuildText

mutual
def inputRefs : BuildText -> List String
  | .literal _ => []
  | .package _ => []
  | .inputPath name => [name]
  | .outPath => []
  | .concat parts => inputRefsList parts

def inputRefsList : List BuildText -> List String
  | [] => []
  | part :: rest => part.inputRefs ++ inputRefsList rest
end

mutual
def packageRefs : BuildText -> List String
  | .literal _ => []
  | .package name => [name]
  | .inputPath _ => []
  | .outPath => []
  | .concat parts => packageRefsList parts

def packageRefsList : List BuildText -> List String
  | [] => []
  | part :: rest => part.packageRefs ++ packageRefsList rest
end

end BuildText

namespace BuildPlan

def joinArgs : List String -> String
  | [] => ""
  | arg :: [] => arg
  | arg :: rest => arg ++ " " ++ joinArgs rest

def argSuffix (args : List String) : String :=
  match args with
  | [] => ""
  | _ => " " ++ joinArgs args

def inputRefs : BuildPlan -> List String
  | .nixpkgsPackage _ => []
  | .executableTextWrapper _ => []
  | .copyInputTree args => [args.inputName]
  | .copyInputFile args => [args.inputName]
  | .installTextFile args => args.content.inputRefs

def packageRefs : BuildPlan -> List String
  | .nixpkgsPackage _ => []
  | .executableTextWrapper args => [args.packageName]
  | .copyInputTree _ => []
  | .copyInputFile _ => []
  | .installTextFile args => args.content.packageRefs

def toBuildExpr : BuildPlan -> BuildExpr
  | .nixpkgsPackage package => .nixpkgs package.toAttr
  | .executableTextWrapper args =>
      .runSteps args.derivationName [.package args.packageName] [
        .installExecutableTextScript args.destination (
          .concat [
            .literal "#!/bin/sh\n",
            .package args.packageName,
            .literal ("/" ++ args.executablePath ++ argSuffix args.arguments ++ "\n")
          ]
        )
      ]
  | .copyInputTree args =>
      .runSteps args.derivationName [] [
        .copySource (.inputPath args.inputName) args.destination,
        .run "touch \"$out\""
      ]
  | .copyInputFile args =>
      .runSteps args.derivationName [] [
        .copySource (.inputPath args.inputName) "source",
        .mkdir "$out",
        .copyFile ("source/" ++ args.sourcePath) args.destination
      ]
  | .installTextFile args =>
      .runSteps args.derivationName [] [
        .installTextFile args.destination args.content
      ]

end BuildPlan

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

def Package.fromBuildPlan (name : String) (plan : BuildPlan) : Package system where
  name := name
  build := plan.toBuildExpr

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

structure PackageExecutableCommand where
  packageName : String
  executable : String
  arguments : List String := []
  deriving Repr, BEq

structure InputPathCheckCommand where
  inputName : String
  path : String
  deriving Repr, BEq

inductive CheckCommand where
  | rawShell : String -> CheckCommand
  | packageExecutableToOutput : PackageExecutableCommand -> CheckCommand
  | inputPathExists : InputPathCheckCommand -> CheckCommand
  deriving Repr, BEq

instance : Coe String CheckCommand where
  coe := CheckCommand.rawShell

structure Check (system : System) where
  name : String
  packageName : String
  command : CheckCommand
  deriving Repr, BEq

structure Formatter (system : System) where
  packageName : String
  deriving Repr, BEq

structure Outputs where
  packages : (system : System) -> List (Package system)
  apps : (system : System) -> List (App system)
  devShells : (system : System) -> List (DevShell system)
  checks : (system : System) -> List (Check system)
  formatter : (system : System) -> Option (Formatter system) := fun _ => none

def Outputs.empty : Outputs where
  packages := fun _ => []
  apps := fun _ => []
  devShells := fun _ => []
  checks := fun _ => []
  formatter := fun _ => none

structure Flake where
  description : String
  inputs : List (String × Input) := []
  outputs : Outputs := Outputs.empty

end Leanix
