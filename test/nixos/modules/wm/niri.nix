# test/nixos/modules/wm/niri.nix --- tests for modules/wm/niri/default.nix
#
# The module renders the host facts into a generated ~/.config/niri/config.kdl
# and publishes what the WM-agnostic modules read (session, primary, outputs).
# None of that fails a build when it drifts: a wrong include order silently
# loses a setting, a missing open-on-output lands a workspace on the wrong
# monitor. So the tests read the generated text and the published options.

{ evalConfig, presets, lib, ... }:

with lib;
let
  niri = modules: evalConfig ([{ modules.wm.desktop = "niri"; }] ++ modules);
  kdl = c: c.home.configFile."niri/config.kdl".text;
  lines = c: splitString "\n" (kdl c);

  two = niri [{ modules.wm.niri.monitors = [
    { output = "DP-1"; }
    { output = "DP-2"; primary = true; mode = "2560x1440@120"; position = { x = 1920; y = 0; }; vrr = "on-demand"; }
  ]; }];

  failing = c: length (filter (a: !a.assertion) c.assertions);
  # The body of one `NAME {` block, up to its first closing brace.
  blockOf = header: text: head (splitString "}" (last (splitString header text)));
in {
  ## The generated file.

  # An include overrides what came before it and is overridden by what comes
  # after, so the live config has to be the first thing in the file or the
  # host facts rendered below it would lose. Absolute, because a relative
  # include resolves against the symlink's directory, not the store's.
  testLiveConfigIsIncludedFirst =
    let incs = filter (hasPrefix "include") (lines presets.niri);
    in {
      expr = head incs;
      expected = ''include "${presets.niri.hey.configDir}/niri/config.kdl"'';
    };

  # Noctalia renders colors.kdl after the first login; a hard include of a
  # missing file is a config error, and niri would fall back to its defaults.
  testColorsIncludeIsOptional = {
    expr = hasInfix ''include optional=true "${presets.niri.home.configDir}/niri/colors.kdl"''
                    (kdl presets.niri);
    expected = true;
  };

  # niri sets XCURSOR_THEME/SIZE for everything it spawns from its own cursor
  # block, over theme.nix's session env; the generated file has to carry the
  # theme's values or every app gets niri's default cursor.
  testCursorFollowsTheTheme =
    let c = niri [{ modules.wm.theme.cursor = { name = "Probe"; size = 48; }; }];
        body = blockOf "\ncursor {" (kdl c);
    in {
      expr = { theme = hasInfix ''xcursor-theme "Probe"'' body; size = hasInfix "xcursor-size 48" body; };
      expected = { theme = true; size = true; };
    };

  # One output block per monitor, with focus-at-startup on the primary and
  # only there -- niri's only notion of primary.
  testMonitorsRenderAsOutputs =
    let text = kdl two; in {
      expr = {
        count   = length (filter (hasPrefix ''output "'') (lines two));
        primary = hasInfix "focus-at-startup" (blockOf ''output "DP-2" {'' text);
        spare   = hasInfix "focus-at-startup" (blockOf ''output "DP-1" {'' text);
        vrr     = hasInfix "variable-refresh-rate on-demand=true" text;
        pos     = hasInfix "position x=1920 y=0" text;
        mode    = hasInfix ''mode "2560x1440@120"'' text;
      };
      expected = { count = 2; primary = true; spare = false; vrr = true; pos = true; mode = true; };
    };

  # The named workspaces are the stand-in for special workspaces, and they
  # have to open on the primary or niri puts them on whichever output it sorts
  # first. Without a primary they're left to niri, not pinned to nothing.
  testNamedWorkspacesOpenOnThePrimary = {
    expr = {
      pinned   = all (w: hasInfix ''open-on-output "DP-2"'' (blockOf ''workspace "${w}" {'' (kdl two)))
                     [ "media" "scratchpad" ];
      unpinned = all (w: hasInfix ''workspace "${w}" {'' (kdl presets.niri)
                         && !hasInfix "open-on-output" (blockOf ''workspace "${w}" {'' (kdl presets.niri)))
                     [ "media" "scratchpad" ];
    };
    expected = { pinned = true; unpinned = true; };
  };

  # Host config is last so it can override anything above it.
  testExtraConfigLandsLast =
    let c = niri [{
          modules.wm.niri.extraConfig = "// HOST-MARKER";
          modules.wm.niri.monitors = [{ output = "DP-1"; }];
        }];
        parts = splitString "// HOST-MARKER" (kdl c);
    in {
      expr = {
        before = hasInfix ''output "DP-1"'' (head parts) && hasInfix ''workspace "media"'' (head parts);
        after  = any (hasInfix ''output "'') (tail parts);
      };
      expected = { before = true; after = false; };
    };

  ## What the WM-agnostic modules read off it.

  testSessionAndPrimaryArePublished = {
    expr = {
      session = two.modules.wm.session.name;
      greeter = two.services.displayManager.noctalia-greeter.settings.session.default;
      after   = elem two.modules.wm.session.unit two.systemd.user.services.hey-shutdown-hook.after;
      primary = two.modules.wm.primaryMonitor;
      outputs = two.modules.wm.outputs;
      info    = two.hey.info.wm.primaryMonitor;
      noPrim  = presets.niri.modules.wm.primaryMonitor;
    };
    expected = {
      session = "niri"; greeter = "Niri"; after = true;
      primary = "DP-2"; outputs = [ "DP-1" "DP-2" ]; info = "DP-2"; noPrim = null;
    };
  };

  # A primary with no name would render `output ""` and name no monitor to
  # Noctalia.
  testPrimaryNeedsAnOutput = {
    expr = failing (niri [{ modules.wm.niri.monitors = [{ primary = true; }]; }]) > failing presets.niri;
    expected = true;
  };

  # The template rides theme.nix, which used to be hyprland-only.
  testColorsTemplateIsRegistered = {
    expr = presets.niri.modules.wm.noctalia.settings.theme.templates.user ? niri;
    expected = true;
  };
}
