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

  workstation = evalConfig [{ modules.profiles.role = "workstation"; }];
  # Not "server": role/server.nix pins a kernel nixpkgs removed, so forcing
  # systemPackages under it won't evaluate at all right now.
  vm = evalConfig [{ modules.profiles.role = "vm"; }];

  hooked = evalConfig [{
    hey.hooks.onFoo = {
      bar = "echo bar";
      # Already numbered: left alone, so a host can put itself first or last.
      "10-baz" = "echo baz";
    };
  }];

  hookNames = c: sort lessThan
    (filter (hasPrefix "hey/hooks.d/") (attrNames c.home.dataFile));

  janetPath = c: splitString ":" c.environment.sessionVariables.JANET_PATH;
in {
  ## Hooks.

  # The 50- is what leaves room on both sides for a host to sequence itself
  # against, and `hey hook` only honours it because ls sorts. Both halves have
  # to hold or the ordering is a fiction.
  testHookFilenamesAreNumbered = {
    expr = hookNames hooked;
    expected = [
      "hey/hooks.d/onFoo.d/10-baz"
      "hey/hooks.d/onFoo.d/50-bar"
    ];
  };

  testNoHooksNoFiles = {
    expr = hookNames bare;
    expected = [];
  };

  # hey hook drops a handler that isn't executable and says nothing about it --
  # `hey hook -l` hides it too, so a regression here is invisible from both ends.
  testHooksAreExecutable = {
    expr = hooked.home.dataFile."hey/hooks.d/onFoo.d/50-bar".executable;
    expected = true;
  };

  # The fragments are zsh, and reach hey.do/hey.echo through /etc/zshenv. A
  # missing shebang would make them sh.
  testHooksAreZshScripts = {
    expr = hooked.home.dataFile."hey/hooks.d/onFoo.d/50-bar".text;
    expected = "#!/usr/bin/env zsh\necho bar\n";
  };

  ## JANET_PATH.

  # janet makes the LAST entry :syspath and searches it ahead of every other, so
  # last means wins. Mine goes there; hey's own libraries are the fallback. Get
  # this backwards and a `jpm install`ed spork silently loses to hey's pinned
  # one, which is the failure this ordering exists to prevent.
  testJanetPathPutsMyOwnTreeLast = {
    expr = last (janetPath bare);
    expected = "/home/test/.local/share/janet/lib";
  };

  # The other entry is hey-janet-libs, which is what the janet scripts hey
  # dispatches to but doesn't compile in (config/rofi/bin/*.janet) import hey
  # from.
  testJanetPathCarriesHeysLibraries = {
    expr = let p = janetPath bare; in {
      count = length p;
      libs = hasSuffix "-hey-janet-libs" (head p);
    };
    expected = { count = 2; libs = true; };
  };

  # JANET_TREE and the tmpfiles rule have to name the same directory the path
  # above ends in; they were three separate spellings of it once.
  testJanetTreeIsMine = {
    expr = bare.environment.sessionVariables.JANET_TREE;
    expected = "/home/test/.local/share/janet";
  };

  testJanetTreeIsCreated = {
    expr = elem "d /home/test/.local/share/janet 755 - - - -"
                bare.systemd.user.tmpfiles.rules;
    expected = true;
  };

  ## Packages.

  testHeyIsInstalled = {
    expr = any (p: (p.pname or p.name or "") == "hey") bare.environment.systemPackages;
    expected = true;
  };

  # What downstream modules call instead of dealing with $PATH in a unit file
  # (modules/apps/steam.nix's gamemode hooks, for one). Asked for the way they
  # ask for it, because config._module is not on the config evalConfig returns.
  testHeyBinIsTheStoreBinary = {
    expr =
      let c = evalConfig [({ heyBin, ... }: {
                environment.shellAliases.probe = heyBin;
              })];
      in hasSuffix "/bin/hey" c.environment.shellAliases.probe;
    expected = true;
  };
}
