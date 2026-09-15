# test/nixos/lib/modules.nix --- tests for lib/modules.nix
#
# These are the walkers the whole flake is built on: default.nix loads all of
# modules/ through mapModulesRec', flake.nix builds hosts through mapHosts, and
# lib/default.nix loads itself through mapModules. A broken walker takes every
# host eval down with it, so only the rules that fail *quietly* are pinned
# here, against the fixture tree in modules.d/ (see its README).

{ lib, heyLib, ... }:

with lib;
let
  inherit (heyLib) mapModules mapModulesRec' modulePaths;
  fixtures = ./modules.d;
in {
  # A .nix file is taken by its basename; a directory only if it holds a
  # default.nix. default.nix itself, '_'-prefixed names and non-.nix files are
  # all skipped -- and a skipped module is just a module that never loads.
  testMapModulesSkipRules = {
    expr = mapModules fixtures import;
    expected = { alpha = "alpha"; beta = "beta"; };
  };

  # mapModulesRec' flattens the tree, descends into directories without a
  # default.nix (gamma), and takes a default.nix-bearing directory as the
  # directory itself (beta).
  testMapModulesRecPrimeFlattensTheTree = {
    expr = mapModulesRec' fixtures baseNameOf;
    expected = [ "alpha.nix" "beta" "inner.nix" ];
  };

  # Every path comes back rooted in the tree it was read out of. This is the
  # regression guard for interpolating DIR as a path instead of stringifying it:
  # doing so copies the tree into the store, and every path below the top level
  # then points into that copy rather than at the real source.
  testMapModulesRecPrimeDoesNotCopyToTheStore = {
    expr = all (hasPrefix "${toString fixtures}/") (modulePaths fixtures);
    expected = true;
  };
}
