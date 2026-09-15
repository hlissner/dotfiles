# test/nixos/modules/hyprland.nix --- tests for modules/hyprland/default.nix
#
# The module splices hey.info into config/hypr/hyprland.lua as a Lua table and
# wires the session's edges (greeter, sleep, shutdown) to hey's hooks. None of
# that fails a build when it drifts: the Lua indexes nil, the hook never fires.
# So the tests read the data the module publishes, and only touch the generated
# Lua for the one thing that has to be there -- the table itself.

{ evalConfig, lib, flake, system, ... }:

with lib;
let
  hyprland = monitors: evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.monitors = monitors;
  }];

  one = hyprland [{ output = "DP-1"; }];
  two = hyprland [
    { output = "DP-1"; }
    { output = "DP-2"; primary = true; }
  ];
in {
  ## The compositor itself.

  # Hyprland comes from its own flake (whose nixpkgs the whole system follows),
  # and the portal has to be the matching one or the two drift out of
  # protocol. The flake isn't built by Hydra either, so without its cachix
  # every bump compiles the compositor. A stray override or a fallback to
  # nixpkgs' hyprland shows up here rather than as an hour-long rebuild.
  testHyprlandComesFromTheFlakeWithItsCache =
    let cfg = one.programs.hyprland;
        s = one.nix.settings;
        theirs = flake.inputs.hyprland.packages.${system};
    in {
      expr = {
        hyprland = cfg.package.outPath == theirs.hyprland.outPath;
        portal   = cfg.portalPackage.outPath == theirs.xdg-desktop-portal-hyprland.outPath;
        cachix   = elem "https://hyprland.cachix.org" s.substituters
                   && any (hasPrefix "hyprland.cachix.org-1:") s.trusted-public-keys;
      };
      expected = { hyprland = true; portal = true; cachix = true; };
    };

  ## The hey table.

  # hey/info.json is spliced in as a lua literal rather than read at runtime,
  # so config/hypr/ reaches it as `hey.*`. Everything the Lua side knows about
  # this machine arrives through this one table -- if it stops being emitted,
  # every consumer silently indexes nil.
  testHeyTableIsEmitted = {
    expr = hasInfix ''["host"] = "test"'' one.home.configFile."hypr/hyprland.lua".text;
    expected = true;
  };

  # Monitors reach config/hypr/ as data, overrides and all.
  testMonitorsReachHeyInfo = {
    expr =
      let m = head (hyprland [{
            output = "DP-2"; mode = "3840x2160@120"; scale = 2; vrr = 1;
          }]).hey.info.hypr.monitors;
      in { inherit (m) output mode scale vrr; };
    expected = { output = "DP-2"; mode = "3840x2160@120"; scale = 2; vrr = 1; };
  };

  # Wayland has no notion of a primary monitor; config/hypr/ fakes it with an
  # xrandr call on session start, and all this module owes it is the name.
  # With no primary the key has to be null: generators.toLua drops it, and
  # `if hey.hypr.primaryMonitor then` needs that. An empty string would be
  # truthy in Lua and name a monitor that doesn't exist.
  testPrimaryMonitorIsNamedOrAbsent = {
    expr = {
      named  = two.hey.info.hypr.primaryMonitor;
      absent = one.hey.info.hypr.primaryMonitor;
    };
    expected = { named = "DP-2"; absent = null; };
  };

  ## The login path.

  # The greeter's compositor lights every output unless told which one, and on
  # nvidia every re-enable is a full link retrain. Pinned to the primary; a
  # host without one is left alone rather than pinned to nothing.
  testGreeterIsPinnedToThePrimaryMonitor = {
    expr = {
      pinned   = two.services.displayManager.noctalia-greeter.settings.output.name;
      unpinned = one.services.displayManager.noctalia-greeter.settings ? output;
    };
    expected = { pinned = "DP-2"; unpinned = false; };
  };

  ## The session's edges.

  # The backstop for a shutdown nobody announced (a bare `systemctl poweroff`).
  # It only buys anything by stopping before what it needs: ordered after the
  # compositor and pipewire, so ExecStop lands while both can still serve a fade
  # and a sound. partOf is what makes the session dying stop it at all.
  testShutdownHookWaitsForTheShell =
    let unit = one.systemd.user.services.hey-shutdown-hook; in {
      expr = {
        after  = all (s: elem s unit.after)
                   [ "wayland-wm@hyprland.desktop.service" "pipewire.service" ];
        partOf = elem "graphical-session.target" unit.partOf;
        stop   = hasInfix "hook -f on-shutting-down" unit.serviceConfig.ExecStop;
      };
      expected = { after = true; partOf = true; stop = true; };
    };

  # Noctalia has no suspend/resume events, so these are systemd's, run as the
  # user from root's side of the fence. Each has to name its own hook, and
  # on-wakeup only runs at all because stopping the unit is what triggers it.
  testSleepHooksReachTheUsersSession =
    let unit = one.systemd.services.hey-sleep-hook; in {
      expr = {
        down    = hasInfix "hook -f on-suspend" unit.script;
        up      = hasInfix "hook -f on-wakeup" unit.preStop;
        asUser  = hasInfix "--machine=test@.host" unit.script;
        onSleep = elem "sleep.target" unit.wantedBy;
        stops   = unit.unitConfig.StopWhenUnneeded;
      };
      expected = { down = true; up = true; asUser = true; onSleep = true; stops = true; };
    };
}
