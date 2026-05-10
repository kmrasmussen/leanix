{
  description = "Leanix proof-carrying CLI closure showcase";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        helloWrapper = pkgs.runCommand "hello-wrapper" { nativeBuildInputs = [ self.packages.${system}.helloTool ]; } ''
          mkdir -p "$out/bin"
          cat > "$out/bin/hello-wrapper" <<'EOF'
#!/bin/sh
${self.packages.${system}.helloTool}/bin/hello --version
EOF
          chmod +x "$out/bin/hello-wrapper"
        '';
        helloTool = pkgs.hello;
        default = pkgs.runCommand "hello-wrapper" { nativeBuildInputs = [ self.packages.${system}.helloTool ]; } ''
          mkdir -p "$out/bin"
          cat > "$out/bin/hello-wrapper" <<'EOF'
#!/bin/sh
${self.packages.${system}.helloTool}/bin/hello --version
EOF
          chmod +x "$out/bin/hello-wrapper"
        '';
      };
      apps.${system} = {
        default = { type = "app"; program = "${self.packages.${system}.helloWrapper}/bin/hello-wrapper"; };
      };
      devShells.${system} = {
        default = pkgs.mkShell { packages = [ self.packages.${system}.helloWrapper ]; };
      };
      checks.${system} = {
        default = pkgs.runCommand "default-check" { nativeBuildInputs = [ self.packages.${system}.helloWrapper ]; } ''
          hello-wrapper > "$out"
        '';
      };
    };
}
