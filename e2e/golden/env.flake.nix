{
  description = "Leanix env var example";

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
        "envEcho" = pkgs.runCommand "env-echo" { nativeBuildInputs = [  ]; env = { "LEANIX_MESSAGE" = "hello from Leanix env"; }; } ''
          test "$LEANIX_MESSAGE" = "hello from Leanix env"
mkdir -p "$out"
printf "%s\n" "$LEANIX_MESSAGE" > "$out/message"
        '';
        "default" = self.packages.${system}."envEcho";
      };
      devShells."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "env" = pkgs.mkShell { packages = [ self.packages.${system}."envEcho" ]; env = { "LEANIX_MESSAGE" = "hello from Leanix shell"; }; };
      };
      checks."x86_64-linux" = let
        system = "x86_64-linux";
        pkgs = pkgsFor system;
      in {
        "envEcho" = pkgs.runCommand "envEcho-check" { nativeBuildInputs = [ self.packages.${system}."envEcho" ]; } ''
          touch "$out"
        '';
      };
    };
}
