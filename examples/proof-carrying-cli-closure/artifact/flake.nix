{
  description = "Leanix proof-carrying CLI closure showcase";

  inputs = {
    "nixpkgs" = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "549bd84d6279f9852cae6225e372cc67fb91a4c1";
      narHash = "sha256-hGdgeU2Nk87RAuZyYjyDjFL6LK7dAZN5RE9+hrDTkDU=";
    };
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
        "default" = pkgs.mkShell { packages = [ self.packages.${system}."helloWrapper" ]; };
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "default" = pkgs.runCommand "default-check" { nativeBuildInputs = [ self.packages.${system}."helloWrapper" ]; } ''
          hello-wrapper > "$out"
        '';
      };
    };
}
