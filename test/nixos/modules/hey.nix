# test/nixos/modules/hey.nix --- tests for modules/hey.nix
#
# This module decides what `hey` is on a running system, and almost everything
# it declares is a runtime contract that fails quietly. hey.hooks in particular
# had no coverage at all, which is how bin/hey.d/hook.janet came to ignore the
# NN- prefixes this module spends a function generating.

{ evalConfig, evalConfig', mkHey, presets, dir, lib, ... }:

with lib;
let
  inherit (presets) bare;

  hooked = evalConfig' (mkHey { hostDir = "${dir}/hosts/udon"; }) [{
    hey.hooks.onFoo = {
      bar = "echo bar";
      # Already numbered: the number is the order, the rest is the name.
      "10-baz" = "echo baz";
    };
    hey.hooks.onBar.bar = "echo bar";
    hey.hookPaths = [ "/elsewhere" ];
  }];

  dataDir = hooked.home.dataDir;
  hasPath = cfg: p: elem "${dir}/${p}" cfg.hey.hookPaths;
in {
  ## Hooks.

  # One directory per fragment NAME, one NN-HOOK file per hook in it, so each
  # is just another hooks dir to `hey hook`. The 50- is what leaves room on
  # both sides for a host to sequence itself against. The fragments are zsh (a
  # missing shebang would make them sh) and have to be executable: `hey hook`
  # drops a handler that isn't, and `hey hook -l` hides it too.
  testHooksLandNumberedExecutableAndZsh =
    let file = hooked.home.dataFile."hey/hooks.d/bar.d/50-onFoo"; in {
      expr = {
        names = sort lessThan (filter (hasPrefix "hey/hooks.d/") (attrNames hooked.home.dataFile));
        executable = file.executable;
        zsh = hasPrefix "#!/usr/bin/env zsh\n" file.text;
      };
      expected = {
        names = [ "hey/hooks.d/bar.d/50-onBar"
                  "hey/hooks.d/bar.d/50-onFoo"
                  "hey/hooks.d/baz.d/10-onFoo" ];
        executable = true;
        zsh = true;
      };
    };

  # hey.hookPaths is the whole of what `hey hook` searches, via info.json. The
  # built-ins go first -- they're the tie-breaker -- and have to survive a
  # module setting its own, which an option default wouldn't. The host's is the
  # live checkout's, not hostDir's store copy.
  testHookPathsSeedHostAndFragmentsFirst = {
    expr = {
      head = take 3 hooked.hey.hookPaths;
      mine = elem "/elsewhere" hooked.hey.hookPaths;
      published = hooked.hey.info.hooks == hooked.hey.hookPaths;
    };
    expected = {
      head = [ "${dir}/hosts/udon/hooks"
               "${dataDir}/hey/hooks.d/bar.d"
               "${dataDir}/hey/hooks.d/baz.d" ];
      mine = true;
      published = true;
    };
  };

  # The point of the list: an area fires only if this host enables it. The WM's
  # dir comes from hey.desktop, which a tty hasn't got; dms and noctalia add
  # their own; config/dms/hooks existing on disk proves nothing.
  testHookPathsFollowEnabledAreas = {
    expr = {
      hypr = hasPath presets.hyprland "config/hypr/hooks";
      noctalia = hasPath presets.hyprland "config/noctalia/hooks";
      dms = hasPath presets.hyprland "config/dms/hooks";
      dmsOn = hasPath (evalConfig [{
        modules.wm.desktop = "hyprland";
        modules.wm.dms.enable = true;
      }]) "config/dms/hooks";
      headless = hasPath presets.bare "config/hypr/hooks";
    };
    expected = {
      hypr = true; noctalia = true; dms = false; dmsOn = true; headless = false;
    };
  };

  ## JANET_PATH.

  # janet makes the LAST entry :syspath and searches it ahead of every other, so
  # last means wins. My tree goes there; hey's own libraries (what the janet
  # scripts hey dispatches to but doesn't compile in import from) are the
  # fallback. Get this backwards and a `jpm install`ed spork silently loses to
  # hey's pinned one. JANET_TREE has to name the same directory, or jpm
  # installs somewhere janet never looks.
  #
  # And no store paths: session vars are frozen at login, so one here pins the
  # scripts to whatever libs I logged in with, however many syncs ago.
  testJanetPathPutsMyOwnTreeLast =
    let v = bare.environment.sessionVariables;
        path = splitString ":" v.JANET_PATH;
    in {
      expr = {
        mine = last path == "${v.JANET_TREE}/lib";
        heys = head path == "/etc/hey/janet"
               && hasSuffix "-hey-janet-libs" "${bare.environment.etc."hey/janet".source}";
        pinned = any (hasPrefix builtins.storeDir) path;
      };
      expected = { mine = true; heys = true; pinned = false; };
    };

  ## The desktop.

  # lib/hey/lib.janet's `wm` reads this out of info.json to find config/NAME.
  # It used to read XDG_CURRENT_DESKTOP, which a tty hasn't got. Headless is
  # null, which spork drops on the way back in, so `wm` sees an absent key and
  # tells you which option to set.
  testDesktopIsPublishedToInfo = {
    expr = {
      hyprland = presets.hyprland.hey.info.desktop;
      headless = bare.hey.info.desktop;
    };
    expected = { hyprland = "hyprland"; headless = null; };
  };
}
