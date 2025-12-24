{
  description = "GodotJS - Godot Engine with JavaScript/TypeScript support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages = {
          default = pkgs.callPackage ./package.nix {};
          godotjs = pkgs.callPackage ./package.nix {};
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/godot";
          };
        };

        # Development shell for maintaining this flake
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            curl
            jq
            git
          ];
        };
      }
    )
    // {
      # Current Version Information
      version = "v1.1.0-editor";

      overlays.default = final: prev: {
        godotjs = final.callPackage ./package.nix {};
      };
    };
}
