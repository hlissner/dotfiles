# test/nixos/lib/pkgs.nix --- tests for lib/pkgs.nix
#
# Both helpers return derivations, so the suite asserts on the names they
# compute rather than on anything built. That is where the bugs have lived:
# mkWrapper used to interpolate its package, which stringified the derivation
# to its store path and named the result after a mangled one, and
# mkLauncherEntry once hashed only the command, so two entries differing in
# title landed on the same file.

{ pkgs, heyLib, ... }:

let
  inherit (heyLib) mkWrapper mkLauncherEntry;

  entry = title: exec:
    (mkLauncherEntry title { inherit exec; icon = "none"; }).name;
in {
  testMkWrapperNamesAfterThePackage = {
    expr = (mkWrapper pkgs.hello "").name;
    expected = "hello-wrapped";
  };

  testMkLauncherEntryNamesDifferByTitleAndExec = {
    expr = {
      title = entry "One" "run" == entry "Two" "run";
      exec  = entry "One" "run" == entry "One" "walk";
    };
    expected = { title = false; exec = false; };
  };
}
