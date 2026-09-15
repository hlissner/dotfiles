# test/nixos/modules/home.nix --- tests for modules/home.nix
#
# modules/home.nix exists to hide home-manager behind four aliases, so that no
# module outside it ever writes home-manager.users.<name>.*. The aliases are
# mkAliasDefinitions plumbing, which fails silently when a rename upstream
# breaks it: files simply stop being deployed.

{ evalConfig, lib, ... }:

with lib;
{
  # fakeFile is the odd one out: not an alias but a rewrite, prefixing every
  # path with home.fakeDir. It is the jail for programs that ignore XDG, so
  # the prefix is the entire point of the option.
  testFileOptionsLandInHomeManager =
    let c = evalConfig [{
          home.configFile."probe/c".text = "c";
          home.dataFile."probe/d".text = "d";
          home.file."probe/f".text = "f";
          home.fakeFile."probe/x".text = "x";
        }];
        hm = c.home-manager.users.test;
    in {
      expr = {
        config = hm.xdg.configFile."probe/c".text;
        data   = hm.xdg.dataFile."probe/d".text;
        file   = hm.home.file."probe/f".text;
        fake   = hm.home.file."${c.home.fakeDir}/probe/x".text;
      };
      expected = { config = "c"; data = "d"; file = "f"; fake = "x"; };
    };

  # home-manager's own xdg homes are mkForce'd to ours, so that nothing
  # downstream can disagree about where $XDG_CONFIG_HOME points.
  testHomeManagerXdgHomesAreOurs =
    let c = evalConfig [];
        x = c.home-manager.users.test.xdg;
    in {
      expr = { inherit (x) cacheHome configHome dataHome stateHome; };
      expected = {
        cacheHome  = c.home.cacheDir;
        configHome = c.home.configDir;
        dataHome   = c.home.dataDir;
        stateHome  = c.home.stateDir;
      };
    };
}
