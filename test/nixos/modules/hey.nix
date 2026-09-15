# test/nixos/modules/hey.nix --- tests for modules/hey.nix
#
# This module decides what `hey` is on a running system, and almost everything
# it declares is a runtime contract that fails quietly. hey.hooks in particular
# had no coverage at all, which is how bin/hey.d/hook.janet came to ignore the
# NN- prefixes this module spends a function generating.

{ evalConfig, lib, ... }:

with lib;
let
  bare = evalConfig [];

  hooked = evalConfig [{
    hey.hooks.onFoo = {
      bar = "echo bar";
      # Already numbered: left alone, so a host can put itself first or last.
      "10-baz" = "echo baz";
    };
  }];
in {
  ## Hooks.

  # The 50- is what leaves room on both sides for a host to sequence itself
  # against, and `hey hook` only honours it because ls sorts. The fragments
  # are zsh (a missing shebang would make them sh) and have to be executable:
  # `hey hook` drops a handler that isn't, and `hey hook -l` hides it too.
  testHooksLandNumberedExecutableAndZsh =
    let file = hooked.home.dataFile."hey/hooks.d/onFoo.d/50-bar"; in {
      expr = {
        names = sort lessThan (filter (hasPrefix "hey/hooks.d/") (attrNames hooked.home.dataFile));
        executable = file.executable;
        zsh = hasPrefix "#!/usr/bin/env zsh\n" file.text;
      };
      expected = {
        names = [ "hey/hooks.d/onFoo.d/10-baz" "hey/hooks.d/onFoo.d/50-bar" ];
        executable = true;
        zsh = true;
      };
    };

  ## JANET_PATH.

  # janet makes the LAST entry :syspath and searches it ahead of every other, so
  # last means wins. My tree goes there; hey's own libraries (what the janet
  # scripts hey dispatches to but doesn't compile in import from) are the
  # fallback. Get this backwards and a `jpm install`ed spork silently loses to
  # hey's pinned one. JANET_TREE has to name the same directory, or jpm
  # installs somewhere janet never looks.
  testJanetPathPutsMyOwnTreeLast =
    let v = bare.environment.sessionVariables;
        path = splitString ":" v.JANET_PATH;
    in {
      expr = {
        mine = last path == "${v.JANET_TREE}/lib";
        heys = any (hasSuffix "-hey-janet-libs") path;
      };
      expected = { mine = true; heys = true; };
    };

  ## The desktop.

  # lib/hey/lib.janet's `wm` reads this out of info.json to find config/NAME.
  # It used to read XDG_CURRENT_DESKTOP, which a tty hasn't got. Headless is
  # null, which spork drops on the way back in, so `wm` sees an absent key and
  # tells you which option to set.
  testDesktopIsPublishedToInfo = {
    expr = {
      hyprland = (evalConfig [{ modules.hyprland.enable = true; }]).hey.info.desktop;
      headless = bare.hey.info.desktop;
    };
    expected = { hyprland = "hyprland"; headless = null; };
  };
}
