{
  description = "Leanix multi-system CLI schema example";

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
        "default" = { type = "app"; program = "${self.packages.${system}."hello"}/bin/hello"; };
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
        "default" = pkgs.runCommand "default-check" { nativeBuildInputs = [ self.packages.${system}."hello" ]; } ''
          hello --version > "$out"
        '';
      };
      packages."aarch64-linux" = let
        system = "aarch64-linux";
        pkgs = pkgsFor system;
      in {
        "hello" = pkgs.hello;
        "default" = self.packages.${system}."hello";
      };
      apps."aarch64-linux" = let
        system = "aarch64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = { type = "app"; program = "${self.packages.${system}."hello"}/bin/hello"; };
      };
      devShells."aarch64-linux" = let
        system = "aarch64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.mkShell { packages = [ self.packages.${system}."hello" ]; };
      };
      checks."aarch64-linux" = let
        system = "aarch64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.runCommand "default-check" { nativeBuildInputs = [ self.packages.${system}."hello" ]; } ''
          hello --version > "$out"
        '';
      };
    };
}
