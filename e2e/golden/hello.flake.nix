{
  description = "Leanix typed hello flake";

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
        "hello" = pkgs.hello;
        "default" = self.packages.${system}."hello";
      };
      apps."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "hello" = { type = "app"; program = "${self.packages.${system}."hello"}/bin/hello"; };
        "default" = self.apps.${system}."hello";
      };
      devShells."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.mkShell { packages = [ self.packages.${system}."hello" ]; };
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "hello" = pkgs.runCommand "hello-check" { nativeBuildInputs = [ self.packages.${system}."hello" ]; } ''
          hello --version > "$out"
        '';
      };
    };
}
