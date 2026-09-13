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
  # Nothing enabled: a headless host must not advertise a fade.
  bare = evalConfig [];

  # How a real host gets this: it asks for the desktop, not for the fade.
  on = evalConfig [{ modules.hyprland.enable = true; }];

  off = evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.fade.enable = false;
  }];

  tuned = evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.fade.duration = 250;
    modules.hyprland.fade.color = "#1a1a1a";
  }];
in {
  ## Wiring.

  # Unlike its plymouth sibling, this one follows modules.hyprland.enable: the
  # hooks and the overlay both live in config/hypr, so there is no host that
  # wants one without the other.
  testFollowsHyprland = {
    expr = on.modules.hyprland.fade.enable;
    expected = true;
  };

  testOffWithoutHyprland = {
    expr = bare.modules.hyprland.fade.enable;
    expected = false;
  };

  ## The runtime contract.

  # These two keys are fade.zsh's entire interface. Renaming either one breaks
  # the fade without breaking the build.
  testInfoCarriesDurationAndColor = {
    expr = on.hey.info.hypr.fade;
    expected = { duration = 1000; color = "#000000"; };
  };

  testInfoFollowsOptions = {
    expr = tuned.hey.info.hypr.fade;
    expected = { duration = 250; color = "#1a1a1a"; };
  };

  # hey.info is `attrsOf attrs`, so hey.info.hypr merges as an opaque shallow
  # union between this module and its parent. Adding .fade must not drop the
  # monitor keys the parent publishes for set-monitors.zsh.
  testInfoDoesNotClobberParent = {
    expr = sort lessThan (attrNames on.hey.info.hypr);
    expected = [ "fade" "monitors" "primaryMonitor" ];
  };

  # Turning it off has to remove the key, not just stop the hooks -- fade.zsh
  # keys its no-op off the key's absence.
  testDisabledPublishesNothing = {
    expr = off.hey.info.hypr ? fade;
    expected = false;
  };

  ## Dependencies.

  # The parent already installs quickshell for screencast's region indicator,
  # so this only fails if both declarations go away at once.
  testQuickshellIsInstalled = {
    expr = any (p: (p.pname or p.name or "") == "quickshell")
               on.environment.systemPackages;
    expected = true;
  };
}
