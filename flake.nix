{
  description = "Zig Ocean Water Simulator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay = {
      # url = "github:mitchellh/zig-overlay/5cf2374c87cbe48139d1571360dcd7dd4807ef1c";
      url = "github:mitchellh/zig-overlay/751dd89e227c60e89c6362fc5cdd5cb814e3f1ba";
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

      lib = pkgs.lib;

      zig-pre = zig-overlay.packages.${system}.master;
      zls = zls-overlay.packages.${system}.default;

      zig = if (isDarwin)
        then zig-pre
        else zig-pre.overrideAttrs (oldAttrs: {
          installPhase = ''
            ${oldAttrs.installPhase}

            mv $out/bin/{zig,.zig-unwrapped}

            cat > $out/bin/zig <<EOF
            #! ${lib.getExe pkgs.dash}
            exec ${lib.getExe pkgs.proot} \\
              --bind=${pkgs.coreutils}/bin/env:/usr/bin/env \\
              $out/bin/.zig-unwrapped "\$@"
            EOF
            chmod +x $out/bin/zig
          '';
        });
      isDarwin = pkgs.stdenv.isDarwin;
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          zig
        ] ++ pkgs.lib.optional (isDarwin) (let
          inherit
            (pkgs.darwin.apple_sdk.frameworks)
              AppKit IOKit Metal CoreServices CoreGraphics Foundation IOSurface QuartzCore;
        in [
          AppKit
          IOKit
          Metal
          CoreServices
          CoreGraphics
          Foundation
          IOSurface
          QuartzCore
        ]);

        buildInputs = with pkgs; [
          zls
          xorg.libX11

          vulkan-headers
          vulkan-loader
          vulkan-tools
        ];
      };
    });
}
