# test/nixos/modules/hyprland.nix --- tests for modules/hyprland/default.nix
#
# This module generates config/hypr/hyprland.lua from cfg.monitors, so a change
# to the option schema or the template silently produces a Hyprland config that
# is wrong rather than one that fails to build. These tests read the generated
# Lua back and assert on what came out.
#
# TODO testExtraConfigLandsInHyprlandPostLua
# TODO testMatugenTemplatesFollowTerminalChoice

{ evalConfig, lib, ... }:

with lib;
let
  hyprland = monitors: evalConfig [{
    modules.hyprland.enable = true;
    modules.hyprland.monitors = monitors;
  }];

  lua = monitors: (hyprland monitors).home.configFile."hypr/hyprland.lua".text;
  greeterConfig = monitors:
    (hyprland monitors).services.displayManager.dms-greeter.compositor.customConfig;

  countMonitors = text: (length (splitString "hl.monitor({" text)) - 1;
in {
  ## Enabling the module.

  # The generic desktop payload -- fonts, the wayland replacements for the old
  # X utilities, rtprio limits -- used to sit in modules/desktop/default.nix
  # and applied to every host unconditionally. It rides with hyprland now, so
  # it has to arrive with the module and stay away when the module is off.
  testEnableBringsTheDesktopPayload = {
    expr = (hyprland [{}]).fonts.fontDir.enable;
    expected = true;
  };

  testDisabledBringsNoDesktopPayload = {
    expr = (evalConfig []).fonts.fontDir.enable;
    expected = false;
  };

  testDisabledByDefault = {
    expr = (evalConfig []).modules.hyprland.enable;
    expected = false;
  };

  # Needed by the DMS screenkey plugin, and easy to lose in a refactor because
  # nothing else in the module mentions it.
  testEnableAddsUserToInputGroup = {
    expr = elem "input" (hyprland [{}]).user.extraGroups;
    expected = true;
  };

  ## Monitor emission.

  testOneMonitorCallPerMonitor = {
    expr = countMonitors (lua [
      { output = "DP-1"; }
      { output = "DP-2"; }
      { output = "DP-3"; }
    ]);
    expected = 3;
  };

  # The submodule's defaults end up verbatim in the Lua, so they are part of
  # this module's contract with config/hypr/, not just with Nix.
  testMonitorDefaultsAreEmitted = {
    expr = hasInfix ''
      hl.monitor({
        output = "DP-1",
        mode = "preferred",
        position = "auto",
        scale = 1,
        disabled = false,
        vrr = 0
      })
    '' (lua [{ output = "DP-1"; }]);
    expected = true;
  };

  testMonitorOverridesAreEmitted = {
    expr = hasInfix ''
      hl.monitor({
        output = "DP-2",
        mode = "3840x2160@120",
        position = "0x0",
        scale = 2,
        disabled = true,
        vrr = 1
      })
    '' (lua [{
      output = "DP-2";
      mode = "3840x2160@120";
      position = "0x0";
      scale = 2;
      disabled = true;
      vrr = 1;
    }]);
    expected = true;
  };

  testHostnameIsEmitted = {
    expr = hasInfix ''HOSTNAME = "test"'' (lua [{ output = "DP-1"; }]);
    expected = true;
  };

  ## The primary monitor, which Wayland has no notion of and which the module
  ## fakes with an xrandr call on session start.

  testPrimaryMonitorIsPickedFromTheList = {
    expr = hasInfix ''PRIMARY_MONITOR = "DP-2"'' (lua [
      { output = "DP-1"; }
      { output = "DP-2"; primary = true; }
    ]);
    expected = true;
  };

  # findFirst returns {} when no monitor is primary, and the whole block is
  # guarded on `primaryMonitor ? output`, so nothing is emitted at all. This is
  # the default case: monitors defaults to [{}], none of them primary.
  testNoPrimaryMonitorEmitsNothing = {
    expr = hasInfix "PRIMARY_MONITOR" (lua [{ output = "DP-1"; }]);
    expected = false;
  };

  testFirstPrimaryWins = {
    expr = hasInfix ''PRIMARY_MONITOR = "DP-1"'' (lua [
      { output = "DP-1"; primary = true; }
      { output = "DP-2"; primary = true; }
    ]);
    expected = true;
  };

  ## The matugen colour fallback.

  # This one reads backwards on purpose, and is pinned so that correcting it has
  # to be a deliberate act. The generated Lua opens hyprland-colors.lua and
  # requires it only in the branch where the file could NOT be opened:
  #
  #   local f = io.open(".../hyprland-colors.lua")
  #   if f ~= nil then io.close(f) else require("hyprland-colors") end
  #
  # If that is ever inverted, the require moves out of the else branch and this
  # test fails.
  testColorsRequireSitsInTheElseBranch = {
    expr =
      let tail = last (splitString "local f = io.open" (lua [{ output = "DP-1"; }]));
          afterElse = last (splitString "else" tail);
      in hasInfix ''require("hyprland-colors")'' afterElse;
    expected = true;
  };

  ## The login path.

  testGreeterIsEnabled = {
    expr = (hyprland [{}]).services.displayManager.dms-greeter.enable;
    expected = true;
  };

  testGreeterRunsInHyprland = {
    expr = (hyprland [{}]).services.displayManager.dms-greeter.compositor.name;
    expected = "hyprland";
  };

  # The greeter used to sweep the outputs away with `output = ""` and put the
  # primary back on the next line. That wildcard took the primary down with it,
  # and on nvidia bringing a monitor back is a full link retrain -- the screen
  # physically blinking off and on between plymouth and the login prompt. Every
  # output is named individually now, and the primary is never disabled.
  testGreeterDisablesEveryOutputButThePrimary =
    let greeter = greeterConfig [
          { output = "DP-1"; }
          { output = "DP-2"; mode = "3840x2160@120"; scale = 2; primary = true; }
          { output = "HDMI-A-1"; disabled = true; }
        ];
    in {
      expr = {
        wildcard   = hasInfix ''output = "",'' greeter;
        disablesDP1 = hasInfix ''hl.monitor({ output = "DP-1", disabled = true })'' greeter;
        disablesTV  = hasInfix ''hl.monitor({ output = "HDMI-A-1", disabled = true })'' greeter;
        keepsPrimary = hasInfix ''
          hl.monitor({
            output = "DP-2",
            mode = "3840x2160@120",
            position = "0x0",
            scale = 2
          })
        '' greeter;
        # One rule per monitor, no wildcard sweep in front of them.
        count = countMonitors greeter;
      };
      expected = {
        wildcard     = false;
        disablesDP1  = true;
        disablesTV   = true;
        keepsPrimary = true;
        count        = 3;
      };
    };

  testGreeterNeedsAPrimaryMonitor = {
    expr = hasInfix "hl.monitor" (greeterConfig [{ output = "DP-1"; }]);
    expected = false;
  };

  # The greeter now owns greetd's default session and runs as its own system
  # user. If this ever reads back as the real user, the greeter has been
  # displaced and the machine is autologging in again.
  testGreetdRunsTheGreeterNotTheUser = {
    expr = (hyprland [{}]).services.greetd.settings.default_session.user;
    expected = "dms-greeter";
  };

  # Declaring the compositor here would generate a second, competing
  # hyprland-uwsm.desktop that collides with the one the Hyprland package
  # already ships.
  testUwsmSessionIsNotGeneratedTwice = {
    expr = attrNames (hyprland [{}]).programs.uwsm.waylandCompositors;
    expected = [];
  };

  testGreeterReadsTheUsersHomeNotItsConfigDir = {
    expr = (hyprland [{}]).services.displayManager.dms-greeter.configHome;
    expected = (hyprland [{}]).user.home;
  };
}
