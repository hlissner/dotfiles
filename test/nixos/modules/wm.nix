# test/nixos/modules/wm.nix --- tests for modules/wm/default.nix
#
# modules.wm.desktop is the only switch a WM has. Get the plumbing wrong and a
# host boots to a tty, or runs a WM that hey.desktop (and so `hey wm`) doesn't
# know about.

{ evalConfig, presets, lib, ... }:

with lib;
let
  inherit (presets) bare;

  # Read off the option's own enum, so a WM joins these tests the moment it
  # joins the option -- there's no list here to forget.
  desktops = presets.nixos.options.modules.wm.desktop.type.nestedTypes.elemType.functor.payload.values;

  desktop = d: evalConfig [{ modules.wm.desktop = d; }];

  # Assumes programs.<desktop> is the WM's own nixpkgs module, which holds for
  # every desktop I've considered.
  running = c: {
    inherit (c.hey) desktop;
    wms = filter (w: c.programs.${w}.enable or false) desktops;
  };

  # Asserted by count against the bare case, never by message.
  failing = c: length (filter (a: !a.assertion) c.assertions);
in {
  testDesktopPicksExactlyOneWM = {
    expr = map running ([ bare ] ++ map desktop desktops);
    expected = [{ desktop = null; wms = []; }]
               ++ map (d: { desktop = d; wms = [ d ]; }) desktops;
  };

  # A splash with nothing to hand off to is a host config mistake, not a
  # feature.
  testWMModulesNeedADesktop =
    let plymouth = extra: evalConfig ([{ modules.wm.plymouth.enable = true; }] ++ extra);
    in {
      expr = {
        orphaned = failing (plymouth []) > failing bare;
        seated   = failing (plymouth [{ modules.wm.desktop = head desktops; }]) == failing bare;
      };
      expected = { orphaned = true; seated = true; };
    };
}
