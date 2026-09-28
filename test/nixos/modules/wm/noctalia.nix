# test/nixos/modules/wm/noctalia.nix --- tests for modules/wm/noctalia.nix
#
# config/noctalia/*.toml is included live; the module only generates what needs
# a host fact. These tests read the merged settings attrset back -- the very
# thing the TOML is generated from -- so nothing has to be built. What's here
# is the plumbing that fails silently: a widget dropped from a lane, a plugin
# gate that never opens, a monitor key that pins the shell to nothing.

{ evalConfig, evalConfig', mkHey, lib, flake, system, dir, ... }:

with lib;
let
  noctalia = monitors: extra: evalConfig ([{
    modules.wm.desktop = "hyprland";
    modules.wm.hyprland.monitors = monitors;
  }] ++ extra);

  settings = monitors: extra:
    (noctalia monitors extra).modules.wm.noctalia.settings;

  # The shape of a real host: one primary, one spare, one disabled.
  three = [
    { output = "DP-1"; }
    { output = "DP-2"; primary = true; }
    { output = "HDMI-A-1"; disabled = true; }
  ];
  base = settings three [];

  # Every plugin gate open at once.
  gatesOpen = [{
    programs.kdeconnect.enable = true;
    modules.profiles.hardware = [ "printer/wireless" "pc/laptop" ];
  }];

  # A host with no primary at all.
  noPrimary = settings [{ output = "DP-1"; }] [];

  # Every widget a bar places, wherever it places it: the three lanes, then the
  # members of each capsule group. `group:<id>` is plumbing, not a widget.
  # Which lane a widget sits in -- or whether it's in a group at all -- is the
  # GUI's business and changes every time I reorganize, so nothing below may
  # name a lane of the real bar.
  placedIn = main:
    filter (w: !hasPrefix "group:" w)
      (concatLists ([ (main.start or []) (main.center or []) (main.end or []) ]
                    ++ map (g: g.members) (main.capsule_group or [])));

  # The lane filter, run over noctalia.d's bar instead of mine. What's on the
  # real bar is the GUI's business, and a test that leans on it breaks every
  # time I rearrange -- or passes vacuously once I take the widget it probed
  # off the bar.
  fixture = extra: (evalConfig' (mkHey { dir = toString ./noctalia.d; }) ([{
    modules.wm.desktop = "hyprland";
  }] ++ extra)).modules.wm.noctalia.settings.bar.main;
  groupsOf = main: listToAttrs (map (g: nameValuePair g.id g.members) (main.capsule_group or []));
in {
  ## The shell.

  # The module reads its hook list out of flake.inputs.noctalia's source, and
  # theme.nix its color tokens, so the shell that runs has to be that one. A
  # fallback to nixpkgs' noctalia would be parsed against the wrong headers.
  testShellIsTheOneWhoseSourceIsParsed = {
    expr = (noctalia [{}] []).programs.noctalia.package.outPath
           == flake.inputs.noctalia.packages.${system}.default.outPath;
    expected = true;
  };

  # The baseline is config/noctalia/ off hey.configDir, which on a real host is
  # the live checkout, so edits need no rebuild. (The harness evaluates a store
  # copy of the flake, so only the shape can be pinned here, not the prefix.)
  testBaselineIsIncludedFromTheConfigDir = {
    expr = any (hasSuffix "/config/noctalia/") base.include.files;
    expected = true;
  };

  ## What the primary monitor pins.

  # Bars spawn on every output, so every monitor but the primary is named and
  # switched off; the lock screen, notifications and login box are named onto
  # the primary. Noctalia reads an empty monitor list as "every output" and
  # throws away a login box with no `output`, so a host with no primary must
  # leave all of these keys off rather than pin them to nothing.
  testPrimaryMonitorPinsTheShell = {
    expr = {
      barOff    = attrNames base.bar.main.monitor;
      lock      = base.lockscreen.monitors;
      toasts    = base.notification.monitors;
      loginBox  = base.lockscreen_widgets.widget."lockscreen-login-box@DP-2".output;
      # And nothing of the sort without one.
      unpinned  = filter (k: noPrimary ? ${k}) [ "lockscreen" "notification" "lockscreen_widgets" ]
                  ++ optional (noPrimary.bar.main ? monitor) "bar";
    };
    expected = {
      barOff = [ "DP-1" "HDMI-A-1" ];
      lock = [ "DP-2" ];
      toasts = [ "DP-2" ];
      loginBox = "DP-2";
      unpinned = [];
    };
  };

  ## The bar.

  # A widget's type names its plugin. Widgets whose plugin this host never
  # installs are dropped rather than left on the bar as dead entries; built-in
  # widgets have no plugin and must survive the filter regardless.
  testBarDropsWidgetsWhosePluginIsNotInstalled =
    let off = fixture [];
        on = fixture [{ programs.kdeconnect.enable = true; }];
    in {
      expr = {
        off     = elem "phone" (placedIn off);
        on      = elem "phone" (placedIn on);
        builtIn = elem "clock" (placedIn off);
      };
      expected = { off = false; on = true; builtIn = true; };
    };

  # A group emptied by the filter has to leave its lane too, or the lane names
  # a group:<id> that no longer exists.
  testBarGroupsLoseMembersNotTheirPlace =
    let main = fixture []; in {
      expr = {
        groups = groupsOf main;
        start = main.start;
      };
      expected = {
        groups = { mixed = [ "clock" ]; };
        start = [];
      };
    };

  # The one built-in widget that needs the same treatment for the opposite
  # reason: it has no plugin to gate it and no setting to hide itself, so a
  # host with no radio would carry a disconnected glyph forever.
  testBarDropsNetworkWidgetWithoutWifi = {
    expr = {
      withoutWifi = elem "network" (placedIn (fixture []));
      withWifi    = elem "network" (placedIn (fixture [{
        modules.profiles.hardware = [ "wifi" ];
      }]));
    };
    expected = { withoutWifi = false; withWifi = true; };
  };

  ## Plugins.

  # Each gate answers for its own plugin. The two that read
  # modules.profiles.hardware match on a prefix, the way the hardware profiles
  # they shadow do: "printer/wireless" is still a printer, so an exact-match
  # gate would quietly miss it. udiskie rides services.udisks2, which
  # modules/system/fs.nix turns on, so it's the one gate open by default.
  testPluginsFollowTheirGates =
    let enabled = extra: (settings three extra).plugins.enabled;
        on = enabled gatesOpen;
        noFs = enabled [{ modules.system.fs.enable = false; }];
    in {
      expr = {
        gated = filter (p: elem p base.plugins.enabled)
          [ "icefish/phone-connect" "andrewdems/printers" "8bury/lid-guard" ];
        opened = filter (p: !elem p on)
          [ "icefish/phone-connect" "andrewdems/printers" "8bury/lid-guard" ];
        udiskie = [ (elem "aristides/udiskie" base.plugins.enabled)
                    (elem "aristides/udiskie" noFs) ];
      };
      expected = { gated = []; opened = []; udiskie = [ true false ]; };
    };

  # My own plugins are the ones that aren't fetched: they sit under the same
  # live config dir the baseline is included from, so a Luau edit is a hot
  # reload rather than a rebuild.
  #
  # `none` is the canary: written as a filter over `hey/*`, every assertion
  # here would pass just as loudly with no local plugins left to check.
  testLocalPluginsAreServedFromTheConfigDir =
    let plugins = (noctalia three []).modules.wm.noctalia.plugins;
        mine = filter (hasPrefix "hey/") (attrNames plugins);
    in {
      expr = {
        none    = mine == [];
        disabled = filter (p: !elem p base.plugins.enabled) mine;
        inStore = filter
          (p: !hasPrefix (head base.include.files) (toString plugins.${p}.src)) mine;
      };
      expected = { none = false; disabled = []; inStore = []; };
    };

  # `[widget.<id>].type` is where a bar entry names its plugin, and a typo
  # there (or a plugin renamed out from under it) drops the widget without a
  # word -- the filter above can't tell it from a plugin this host skips on
  # purpose. So every plugin my real bar names has to be one the module
  # declares, whatever I've put on the bar and wherever. (With every gate open,
  # since the hardware-gated ones are declared behind an mkIf.)
  testBarNamesOnlyDeclaredPlugins =
    let bar = fromTOML (readFile "${dir}/config/noctalia/bar.toml");
        declared = (noctalia three gatesOpen).modules.wm.noctalia.plugins;
        named = filter (hasInfix "/") (catAttrs "type" (attrValues (bar.widget or {})));
    in {
      expr = filter (t: !(declared ? ${head (splitString ":" t)})) named;
      expected = [];
    };

  ## Hooks.

  # Every event hands off to the hook wearing its name in hey's spelling
  # (underscores to hyphens), so a handler is a file in a hooks/ dir and the
  # meaning is never repeated here. The list is Noctalia's, not mine, and the
  # module throws if upstream moves it -- so all that's pinned is that the
  # events config/*/hooks answers are still in it.
  testHooksHandOffToHeyByName = {
    expr = {
      spelled = all (name:
          hasSuffix "/bin/hey hook -f on-${replaceStrings [ "_" ] [ "-" ] name}" base.hooks.${name})
        (attrNames base.hooks);
      answered = filter (x: !(base.hooks ? ${x}))
        [ "colors_changed" "theme_mode_changed" "battery_charging"
          "battery_discharging" "started" "shutting_down" "rebooting" ];
    };
    expected = { spelled = true; answered = []; };
  };

  ## Overrides.

  # Everything generated is mkDefault'd leaf by leaf, so a host overriding one
  # key leaves its siblings standing. mkDefault over the tree as a whole would
  # take the battery hooks down with the theme one here.
  testHostOverridesOneLeafWithoutDroppingItsSiblings =
    let s = settings three [{
          modules.wm.noctalia.settings.hooks.colors_changed = "true";
        }];
    in {
      expr = {
        overridden = s.hooks.colors_changed;
        sibling = hasSuffix "hook -f on-battery-charging" s.hooks.battery_charging;
      };
      expected = { overridden = "true"; sibling = true; };
    };
}
