{
  description = "Leanix multi-app schema example";

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
        "helloTool" = pkgs.hello;
        "helloWrapper" = pkgs.runCommand "hello-wrapper" { nativeBuildInputs = [ self.packages.${system}."helloTool" ]; } ''
          install -D -m755 ${pkgs.writeText "leanix-script" "#!/bin/sh\n${self.packages.${system}."helloTool"}/bin/hello --version\n"} "$out/bin/hello-wrapper"
        '';
        "default" = self.packages.${system}."helloTool";
      };
      apps."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "hello" = { type = "app"; program = "${self.packages.${system}."helloTool"}/bin/hello"; };
        "wrapper" = { type = "app"; program = "${self.packages.${system}."helloWrapper"}/bin/hello-wrapper"; };
        "default" = self.apps.${system}."hello";
      };
      devShells."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.mkShell { packages = [ self.packages.${system}."helloTool" self.packages.${system}."helloWrapper" ]; };
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "wrapper" = pkgs.runCommand "wrapper-check" { nativeBuildInputs = [ self.packages.${system}."helloWrapper" ]; } ''
          hello-wrapper > "$out"
        '';
      };
    };
}
