# test/nixos/modules/home.nix --- tests for modules/home.nix
#
# modules/home.nix funnels every *File and *Link option into home.link, by
# absolute path, and a user activation script hands that to tmpfiles. A path
# that lands in the wrong dir here lands there in $HOME, and a file that goes
# missing here simply stops being deployed, silently.

{ evalConfig, lib, pkgs, ... }:

with lib;
let probes = c: filterAttrs (p: _: hasInfix "probe/" p) c.home.link;
    stored = t: hasPrefix "${builtins.storeDir}/" t;
in {
  # Files become store paths; links are left exactly as given. fakeFile is the
  # jail for programs that ignore XDG, so its prefix is the whole point.
  testEveryOptionLandsUnderItsDir =
    let c = evalConfig [{
          home.file."probe/f".text = "f";
          home.fakeFile."probe/x".text = "x";
          home.configFile."probe/c".text = "c";
          home.dataFile."probe/d".source = pkgs.writeText "d" "d";
          home.link."probe/l" = "/l";
          home.link."/abs/probe/a" = "/a";
          home.configLink."probe/cl" = "/cl";
          home.dataLink."probe/dl" = "/dl";
          home.cacheLink."probe/kl" = "/kl";
          home.stateLink."probe/sl" = "/sl";
        }];
        h = c.home;
    in {
      expr = mapAttrs (_: t: if stored t then "store" else t) (probes c);
      expected = {
        "${h.dir}/probe/f"       = "store";
        "${h.fakeDir}/probe/x"   = "store";
        "${h.configDir}/probe/c" = "store";
        "${h.dataDir}/probe/d"   = "store";
        # Resolved against $HOME only on its way to tmpfiles
        "probe/l"                 = "/l";
        "/abs/probe/a"            = "/a";
        "${h.configDir}/probe/cl" = "/cl";
        "${h.dataDir}/probe/dl"   = "/dl";
        "${h.cacheDir}/probe/kl"  = "/kl";
        "${h.stateDir}/probe/sl"  = "/sl";
      };
    };

  # A recursive source becomes one link per file, so rofi can drop a generated
  # fonts.rasi into a directory it otherwise takes wholesale from config/.
  testRecursiveExplodesAndExplicitWins =
    let c = evalConfig [{
          home.configFile."probe" = { source = ./home.d/tree; recursive = true; };
          home.configFile."probe/a".text = "mine";
        }];
        l = probes c;
        dir = c.home.configDir;
    in {
      expr = {
        paths = attrNames l;
        a = hasSuffix "-a" l."${dir}/probe/a";
        b = hasSuffix "/sub/b" l."${dir}/probe/sub/b";
      };
      expected = {
        paths = [ "${dir}/probe/a" "${dir}/probe/sub/b" ];
        a = true;
        b = true;
      };
    };

  # home-manager resolved mkIf inside an entry for me (librewolf's user.js
  # leans on it); a bare `attrs` type wouldn't.
  testMkIfFalseEntriesVanish = {
    expr = probes (evalConfig [{
      home.configFile."probe/gone" = mkIf false { text = "x"; };
    }]);
    expected = {};
  };

  testEntryWithNothingToLinkThrows = {
    expr = (builtins.tryEval (builtins.deepSeq
      (probes (evalConfig [{ home.configFile."probe/empty" = {}; }])) null)).success;
    expected = false;
  };
}
