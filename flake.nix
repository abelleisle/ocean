{
  description = "Zig ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      zig = zig-overlay.packages.${system}.master-2024-01-07;
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          zig
        ];

        buildInputs = with pkgs; [
          zls
          xorg.libX11
        ];
      };
    });
}
