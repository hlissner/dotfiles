# test/nixos/modules/noctalia.nix --- tests for modules/hyprland/noctalia.nix
#
# config/noctalia/*.toml is included live; the module only generates what needs
# a host fact. These tests read the merged settings attrset back -- the very
# thing the TOML is generated from -- so nothing has to be built. What's here
# is the plumbing that fails silently: a widget dropped from a lane, a plugin
# gate that never opens, a monitor key that pins the shell to nothing.

{ evalConfig, lib, flake, system, dir, ... }:

with lib;
let
  noctalia = monitors: extra: evalConfig ([{
    modules.hyprland.enable = true;
    modules.hyprland.monitors = monitors;
  }] ++ extra);

  settings = monitors: extra:
    (noctalia monitors extra).modules.hyprland.noctalia.settings;

  # The shape of a real host: one primary, one spare, one disabled.
  three = [
    { output = "DP-1"; }
    { output = "DP-2"; primary = true; }
    { output = "HDMI-A-1"; disabled = true; }
  ];
  base = settings three [];

  # A host with no primary at all.
  noPrimary = settings [{ output = "DP-1"; }] [];

  # Every widget a bar places, wherever it places it: the three lanes, then the
  # members of each capsule group. `group:<id>` is plumbing, not a widget.
  # Which lane a widget sits in -- or whether it's in a group at all -- is the
  # GUI's business and changes every time I reorganize, so nothing below may
  # name a lane.
  placedIn = main:
    filter (w: !hasPrefix "group:" w)
      (concatLists ([ (main.start or []) (main.center or []) (main.end or []) ]
                    ++ map (g: g.members) (main.capsule_group or [])));

  onBar = s: w: elem w (placedIn s.bar.main);

  # The unfiltered bar, so a test can tell "the filter dropped it" from "I took
  # it off the bar myself".
  baselineBar = (fromTOML (readFile "${dir}/config/noctalia/bar.toml")).bar.main;
in {
  ## The shell.

  # Pinned as identity with the input, so a fallback to nixpkgs' noctalia
  # shows up here rather than as a version skew against the plugins.
  testShellComesFromTheFlakeWithItsCache =
    let cfg = noctalia [{}] [];
        s = cfg.nix.settings;
    in {
      expr = {
        package = cfg.programs.noctalia.package.outPath
                  == flake.inputs.noctalia.packages.${system}.default.outPath;
        cachix = elem "https://noctalia.cachix.org" s.substituters
                 && any (hasPrefix "noctalia.cachix.org-1:") s.trusted-public-keys;
      };
      expected = { package = true; cachix = true; };
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
  #
  # `fixture` is the canary: phone and workspaces live in a baseline I edit
  # through the GUI, and taking either off the bar would leave the rest of this
  # quietly proving nothing.
  testBarDropsWidgetsWhosePluginIsNotInstalled = {
    expr = {
      off     = onBar base "phone";
      on      = onBar (settings three [{ programs.kdeconnect.enable = true; }]) "phone";
      builtIn = onBar base "workspaces";
      fixture = all (w: elem w (placedIn baselineBar)) [ "phone" "workspaces" ];
    };
    expected = { off = false; on = true; builtIn = true; fixture = true; };
  };

  # The one built-in widget that needs the same treatment for the opposite
  # reason: it has no plugin to gate it and no setting to hide itself, so a
  # host with no radio would carry a disconnected glyph forever.
  testBarDropsNetworkWidgetWithoutWifi = {
    expr = {
      withoutWifi = onBar base "network";
      withWifi    = onBar (settings three [{
        modules.profiles.hardware = [ "wifi" ];
      }]) "network";
      fixture     = elem "network" (placedIn baselineBar);
    };
    expected = { withoutWifi = false; withWifi = true; fixture = true; };
  };

  ## Plugins.

  # Each gate answers for its own plugin. The two that read
  # modules.profiles.hardware match on a prefix, the way the hardware profiles
  # they shadow do: "printer/wireless" is still a printer, so an exact-match
  # gate would quietly miss it. udiskie rides services.udisks2, which
  # modules/system/fs.nix turns on, so it's the one gate open by default.
  testPluginsFollowTheirGates =
    let enabled = extra: (settings three extra).plugins.enabled;
        on = enabled [{
          programs.kdeconnect.enable = true;
          modules.profiles.hardware = [ "printer/wireless" "pc/laptop" ];
        }];
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
  # reload rather than a rebuild. An id has to survive the trip onto the bar
  # too -- a typo on either side drops the widgets silently, which is exactly
  # how you don't find out.
  #
  # `count` is the canary: written as a filter over `hey/*`, every assertion
  # here would pass just as loudly with no local plugins left to check.
  #
  # These are bar ids, which are free to disagree with the plugin's own widget
  # name -- `[widget.<id>].type` is where the plugin gets named, so the lane
  # can call it anything. Mine don't disagree, and that's the point of naming
  # them here.
  testLocalPluginsAreServedFromTheConfigDir =
    let plugins = (noctalia three []).modules.hyprland.noctalia.plugins;
        mine = filter (hasPrefix "hey/") (attrNames plugins);
        placed = placedIn base.bar.main;
    in {
      expr = {
        count   = length mine;
        offBar  = filter (p: !elem p base.plugins.enabled) mine;
        inStore = filter
          (p: !hasPrefix (head base.include.files) (toString plugins.${p}.src)) mine;
        widgets = filter (w: !elem w placed)
          [ "submap" "trackpad-battery" "timer" "screencast" ];
      };
      expected = { count = 4; offBar = []; inStore = []; widgets = []; };
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
          modules.hyprland.noctalia.settings.hooks.colors_changed = "true";
        }];
    in {
      expr = {
        overridden = s.hooks.colors_changed;
        sibling = hasSuffix "hook -f on-battery-charging" s.hooks.battery_charging;
      };
      expected = { overridden = "true"; sibling = true; };
    };
}
