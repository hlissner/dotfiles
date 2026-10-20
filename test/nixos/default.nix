# test/nixos/default.nix --- entry point for checks.<system>.nixos
#
# flake.nix already wires 'checks = mapModules ./test import', and mapModules
# picks up any directory holding a default.nix, so this file is the whole
# hookup.
#
# mapModules is only one level deep, so every suite under test/nixos/ is joined
# into this one derivation. They are also hung off passthru, which keeps
# individual suites addressable while iterating:
#
#   nix build --no-link .#checks.x86_64-linux.nixos
#   nix build --no-link .#checks.x86_64-linux.nixos.passthru.lib-modules
#
# 'flake' comes from the extra callPackage argument that lib/nixos.nix hands to
# checks; the suites need this flake's own inputs to evaluate our modules.

{ lib, pkgs, symlinkJoin, flake, ... }:

let
  testLib = import ./_lib.nix { inherit lib pkgs flake; };

  suites =
    lib.mapAttrs
      (name: path: testLib.mkSuite name (import path testLib))
      (testLib.collectSuites ./.);
in
  symlinkJoin {
    name = "nixos-tests";
    paths = lib.attrValues suites;
    passthru = suites;
    # The check runs where the builders are. An aarch64 host (hosts/pi) is
    # still evaluated, against its own package set (_lib.nix's pkgsFor); the
    # meta.platforms filter in lib/nixos.nix just means aarch64 gets no
    # 'nixos' check of its own.
    meta.platforms = [ "x86_64-linux" ];
  }
