# test/nixos/modules/wm/hyprland.nix --- tests for modules/wm/hyprland/default.nix
#
# The module splices hey.info into config/hypr/hyprland.lua as a Lua table and
# wires the session's edges (greeter, sleep, shutdown) to hey's hooks. None of
# that fails a build when it drifts: the Lua indexes nil, the hook never fires.
# So the tests read the data the module publishes, and only touch the generated
# Lua for the one thing that has to be there -- the table itself.

{ evalConfig, lib, pkgs, flake, system, ... }:

with lib;
let
  hyprland = monitors: evalConfig [{
    modules.wm.desktop = "hyprland";
    modules.wm.hyprland.monitors = monitors;
  }];

  one = hyprland [{ output = "DP-1"; }];
  two = hyprland [
    { output = "DP-1"; }
    { output = "DP-2"; primary = true; }
  ];
in {
  ## The compositor itself.

  # The portal has to come from wherever the compositor does, or the two drift
  # out of protocol -- and nixpkgs' portal is the default, so overriding only
  # the package gets you exactly that. Which source they share is my call.
  testPortalMatchesTheCompositor =
    let cfg = one.programs.hyprland;
        theirs = flake.inputs.hyprland.packages.${system};
    in {
      expr = (cfg.package.outPath == theirs.hyprland.outPath)
             == (cfg.portalPackage.outPath == theirs.xdg-desktop-portal-hyprland.outPath);
      expected = true;
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

  ## Plugins.

  # There's no programs.hyprland.plugins to lean on, so the generated file
  # dlopens them itself -- and it has to do it above `require("hyprland")`,
  # because config/hypr/ reaches straight for hl.plugin.*. Losing the line
  # doesn't fail a build; the guards there just skip the plugin forever. The
  # probe is any package at all; nothing is built, let alone loaded.
  testPluginsLoadBeforeTheConfig =
    let lua = (evalConfig [{
          modules.wm.desktop = "hyprland";
          modules.wm.hyprland.plugins = [ pkgs.hello ];
        }]).home.configFile."hypr/hyprland.lua".text;
        parts = splitString ''require("hyprland")'' lua;
    in {
      expr = {
        early = hasInfix ''/lib/libhello.so")'' (head parts);
        late  = any (hasInfix "hl.plugin.load(") (tail parts);
      };
      expected = { early = true; late = false; };
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

  # Hosts turn config/hypr/'s knobs through the same hey.info.hypr this module
  # fills, so the two have to merge rather than one clobbering (or colliding
  # with) the other. hyprland.lua only defaults what arrives as nil.
  testHostKnobsMergeIntoHeyHypr = {
    expr =
      let h = (evalConfig [{
            modules.wm.desktop = "hyprland";
            modules.wm.hyprland.monitors = [{ output = "DP-1"; primary = true; }];
            hey.info.hypr = { workspace.main = "200"; pad_gaps_in = 5; };
          }]).hey.info.hypr;
      in { inherit (h) primaryMonitor pad_gaps_in; main = h.workspace.main; };
    expected = { primaryMonitor = "DP-1"; pad_gaps_in = 5; main = "200"; };
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
  # compositor, so ExecStop lands while it can still serve a fade. partOf is
  # what makes the session dying stop it at all.
  testShutdownHookWaitsForTheShell =
    let unit = one.systemd.user.services.hey-shutdown-hook; in {
      expr = {
        after  = elem "wayland-wm@hyprland.desktop.service" unit.after;
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
        onSleep = elem "sleep.target" unit.wantedBy;
        stops   = unit.unitConfig.StopWhenUnneeded;
      };
      expected = { down = true; up = true; onSleep = true; stops = true; };
    };
}
