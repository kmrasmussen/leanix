{
  description = "Leanix service schema example";

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
        "helloWrapper" = pkgs.runCommand "hello-wrapper" { nativeBuildInputs = [ self.packages.${system}."helloTool" ]; } ''
          install -D -m755 ${pkgs.writeText "leanix-script" "#!/bin/sh\n${self.packages.${system}."helloTool"}/bin/hello --version\n"} "$out/bin/hello-wrapper"
        '';
        "helloTool" = pkgs.hello;
        "default" = self.packages.${system}."helloWrapper";
      };
      apps."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = { type = "app"; program = "${self.packages.${system}."helloWrapper"}/bin/hello-wrapper"; };
      };
      devShells."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.mkShell { packages = [ self.packages.${system}."helloWrapper" self.packages.${system}."helloTool" ]; };
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "health" = pkgs.runCommand "health-check" { nativeBuildInputs = [ self.packages.${system}."helloWrapper" ]; } ''
          hello-wrapper > "$out"
        '';
      };
    };
}
