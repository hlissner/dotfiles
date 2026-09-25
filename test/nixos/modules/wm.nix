# test/nixos/modules/wm.nix --- tests for modules/wm/default.nix
#
# modules.wm.desktop is the only switch a WM has. Get the plumbing wrong and a
# host boots to a tty, or runs a WM that hey.desktop (and so `hey wm`) doesn't
# know about.

{ evalConfig, lib, ... }:

with lib;
let
  bare = evalConfig [];
  desktop = d: evalConfig [{ modules.wm.desktop = d; }];

  running = c: {
    inherit (c.hey) desktop;
    hyprland = c.programs.hyprland.enable;
    # niri = c.programs.niri.enable;
  };

  # Asserted by count against the bare case, never by message.
  failing = c: length (filter (a: !a.assertion) c.assertions);
in {
  testDesktopPicksExactlyOneWM = {
    expr = {
      none     = running bare;
      hyprland = running (desktop "hyprland");
      # niri     = running (desktop "niri");
    };
    expected = {
      none     = { desktop = null;       hyprland = false; niri = false; };
      hyprland = { desktop = "hyprland"; hyprland = true;  niri = false; };
      # niri     = { desktop = "niri";     hyprland = false; niri = true;  };
    };
  };

  # A splash with nothing to hand off to is a host config mistake, not a
  # feature. niri, because it's the cheapest desktop to evaluate.
  testWMModulesNeedADesktop =
    let plymouth = extra: evalConfig ([{ modules.wm.plymouth.enable = true; }] ++ extra);
    in {
      expr = {
        orphaned = failing (plymouth []) > failing bare;
        # seated   = failing (plymouth [{ modules.wm.desktop = "niri"; }]) == failing bare;
      };
      expected = {
        orphaned = true;
        # seated = true;
      };
    };
}
