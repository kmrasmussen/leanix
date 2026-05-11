{
  description = "Leanix formatter schema example";

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
        "default" = self.packages.${system}."helloTool";
      };
      formatter."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in self.packages.${system}."helloTool";
    };
}
