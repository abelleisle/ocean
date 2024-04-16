{
  description = "Zig ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      url = "github:mitchellh/zig-overlay/5cf2374c87cbe48139d1571360dcd7dd4807ef1c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls-overlay = {
      url = "github:zigtools/zls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # zig-overlay.follows = "zig-overlay";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, zls-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      zig = zig-overlay.packages.${system}.master;
      zls = zls-overlay.packages.${system}.default;
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
