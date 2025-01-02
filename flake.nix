{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Version of requirements.txt installed in pythonEnv
    zephyr.url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
    zephyr.flake = false;

    # Zephyr sdk and toolchain
    zephyr-nix = {
      url = "github:urob/zephyr-nix";
      inputs.zephyr.follows = "zephyr";
      # Relies on 23.11 to provide py38 until zephyr-sdk bumps the requirement
      inputs.nixpkgs.follows = "nixpkgs";
    };


    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, zephyr-nix, zmk-nix, self, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
   packages = forAllSystems (system: rec {
      default = firmware;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        # src = nixpkgs.lib.sourceFilesBySuffices self [ ".conf" ".keymap" ".dts" ".dtsi" ".yml" ".shield" ".overlay" ".defconfig" "_defconfig" ".board" ".cmake" ".json" ".yaml" ];
        src = ./.;

        board = "nice_nano_v2";
        shield = "yeagboard_%PART%";

        zephyrDepsHash = "sha256-F0g6zxr27AdWsJpF58jxMXDQqxTk5v3Ci/MiPlkoHhg=";

        enableZmkStudio = true;

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "adafruit-nrfutil"
          ];
        };
      };
      zephyr = zephyr-nix.packages.${system};
      keymap_drawer = pkgs.python3Packages.callPackage ./draw { };
    in {
      default = pkgs.mkShell {
        inputsFrom = [zmk-nix.devShells.${system}.default];

        # for justfile scripts and local build debugging
        packages = [
          keymap_drawer

          zephyr.pythonEnv
          (zephyr.sdk.override { targets = [ "arm-zephyr-eabi" ]; })

          pkgs.cmake
          pkgs.dtc
          pkgs.ninja
          pkgs.qemu # needed for native_posix target
          pkgs.adafruit-nrfutil

          # Uncomment these if you don't have system-wide versions:
          pkgs.gawk             # awk
          pkgs.unixtools.column # column
          pkgs.coreutils        # cp, cut, echo, mkdir, sort, tail, tee, uniq, wc
          pkgs.diffutils        # diff
          pkgs.findutils        # find, xargs
          pkgs.gnugrep          # grep
          pkgs.just               # just
          pkgs.gnused           # sed
          pkgs.yq                 # yq
          pkgs.protobuf         # protoc
          pkgs.nanopb
          pkgs.inkscape        # inkscape (for svg -> png conversion)
        ];
      };
    });
  };
}
