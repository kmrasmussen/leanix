{
  description = "Leanix build plan text file example";

  inputs = {
    "nixpkgs".url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "plannedTextFile" = pkgs.runCommand "planned-text-file" { nativeBuildInputs = [  ]; } ''
          install -D -m644 ${pkgs.writeText "leanix-file" "hello from BuildPlan text file\n"} "$out/message.txt"
        '';
        "default" = self.packages.${system}."plannedTextFile";
      };
    };
}
