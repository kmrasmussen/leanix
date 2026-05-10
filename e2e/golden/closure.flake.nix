{
  description = "Leanix typed closure example";

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
          install -D -m755 ${pkgs.writeText "leanix-script" "#!/bin/sh\n${self.packages.${system}.helloTool}/bin/hello --version"} "$out/bin/hello-wrapper"
        '';
        "default" = self.packages.${system}."helloTool";
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "helloWrapper" = pkgs.runCommand "helloWrapper-check" { nativeBuildInputs = [ self.packages.${system}."helloWrapper" ]; } ''
          hello-wrapper > "$out"
        '';
      };
    };
}
