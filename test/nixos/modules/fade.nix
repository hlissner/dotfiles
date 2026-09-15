# test/nixos/modules/fade.nix --- tests for modules/hyprland/fade.nix
#
# The module itself is tiny; what it really publishes is a runtime contract.
# config/hypr/bin/fade.zsh reads `hey info hypr fade` and silently no-ops when
# that key is missing, so a regression here is invisible -- the fade just stops
# happening, and the hooks keep exiting 0. Hence the emphasis on the shape of
# hey.info rather than on the options.

{ evalConfig, lib, ... }:

with lib;
let
  bare = evalConfig [];
  on = evalConfig [{ modules.hyprland.enable = true; }];
in {
  # Unlike its plymouth sibling, this one has no switch of its own: it rides
  # the desktop. fade.zsh keys its no-op off the absence of the info key, so a
  # headless host has to publish nothing rather than publish a fade nobody
  # draws.
  testFollowsTheDesktop = {
    expr = {
      hyprland = on.hey.info.hypr ? fade;
      headless = (bare.hey.info.hypr or {}) ? fade;
    };
    expected = { hyprland = true; headless = false; };
  };

  # These two keys are fade.zsh's entire interface. Renaming either one breaks
  # the fade without breaking the build. And hey.info is `attrsOf attrs`, so
  # hey.info.hypr merges as an opaque shallow union between this module and its
  # parent: adding .fade must not drop the monitor keys the parent publishes.
  testInfoCarriesTheOptionsBesideTheParents =
    let tuned = evalConfig [{
          modules.hyprland.enable = true;
          modules.hyprland.fade.duration = 250;
          modules.hyprland.fade.color = "#1a1a1a";
        }];
    in {
      expr = {
        fade = tuned.hey.info.hypr.fade;
        parent = tuned.hey.info.hypr ? monitors;
      };
      expected = { fade = { duration = 250; color = "#1a1a1a"; }; parent = true; };
    };
}
