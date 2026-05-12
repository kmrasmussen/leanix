{
  description = "Leanix pinned flake input example";

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
