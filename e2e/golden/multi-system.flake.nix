{
  description = "Leanix multi-system renderer example";

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
      packages."aarch64-linux" = let
        system = "aarch64-linux";
        pkgs = pkgsFor system;
      in {
        "hello" = pkgs.hello;
        "default" = self.packages.${system}."hello";
      };
    };
}
