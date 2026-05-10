{
  description = "Lean-native typed flakes and reproducible build modeling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs { inherit system; }));
    in
    {
      checks = forAllSystems (pkgs: {
        build = pkgs.runCommand "leanix-build"
          {
            nativeBuildInputs = [
              pkgs.lean4
              pkgs.cargo
              pkgs.rustc
              pkgs.stdenv.cc
              pkgs.git
            ];
            src = self;
          } ''
          cp -R "$src" source
          chmod -R u+w source
          cd source
          lake build
          cargo check --locked --manifest-path e2e/runner/Cargo.toml
          touch "$out"
        '';
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.lean4
            pkgs.cargo
            pkgs.rustc
            pkgs.rustfmt
            pkgs.git
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
