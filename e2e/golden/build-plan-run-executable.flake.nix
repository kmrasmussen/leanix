{
  description = "Leanix build plan run executable example";

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
        "helloVersion" = pkgs.runCommand "hello-version" { nativeBuildInputs = [ self.packages.${system}."helloTool" ]; } ''
          hello --version > "$out"
        '';
        "helloTool" = pkgs.hello;
        "default" = self.packages.${system}."helloVersion";
      };
    };
}
