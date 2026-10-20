# test/nixos/modules/games/doom.nix --- tests for modules/games/doom.nix
#
# The module is a courier: doommenu reads both paths out of info.json, so a
# renamed key there is a menu that aborts, and the launcher entry is the only
# way in from rofi.

{ evalConfig, lib, pkgs, ... }:

with lib;
let
  on = evalConfig [{ modules = {
    # rofi's own entries name the default browser; without one they're nulls.
    apps.rofi.enable = true;
    apps.browsers.default = "firefox";
    games = {
      steam.libraryDir = "/lib";
      doom = { enable = true; wadsDir = "/wads"; };
    };
  }; }];
  info = fromJSON on.home.dataFile."hey/info.json".text;
in {
  testMenuGetsItsPathsFromInfoJson = {
    expr = {
      doom = info.doom;
      wadDir = on.environment.sessionVariables.DOOMWADDIR;
    };
    expected = {
      doom = { iwad = "/lib/steamapps/common/Doom 2/base/DOOM2.WAD"; wadsDir = "/wads"; };
      wadDir = "/lib/steamapps/common/Doom 2/base";
    };
  };

  testLauncherEntryOpensTheMenu = {
    expr =
      let entry = findFirst (p: hasInfix "Name=Doom ->\n" (toString (p.text or ""))) null on.user.packages;
      in entry != null && hasInfix "\nExec=hey @rofi doommenu\n" entry.text;
    expected = true;
  };

  # Steam's own default library, when a host doesn't move it.
  testIwadDefaultsToSteamsDataDir = {
    expr =
      let c = evalConfig [{ modules.games.doom.enable = true; }];
      in c.modules.games.doom.iwad == "${c.home.dataDir}/Steam/steamapps/common/Doom 2/base/DOOM2.WAD";
    expected = true;
  };
}
