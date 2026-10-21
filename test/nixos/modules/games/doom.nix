# test/nixos/modules/games/doom.nix --- tests for modules/games/doom.nix
#
# The module is a courier: doommenu reads both paths out of info.json, so a
# renamed key there is a menu that aborts. Where the paths point is the module's
# business (and the host's), so nothing here says what they are.

{ evalConfig, lib, ... }:

with lib;
let
  on = evalConfig [{ modules.games.doom = { enable = true; wadsDir = "/wads"; }; }];
  doom = on.modules.games.doom;
  info = fromJSON on.home.dataFile."hey/info.json".text;
in {
  testMenuGetsItsPathsFromInfoJson = {
    expr = {
      inherit (info) doom;
      wadDir = on.environment.sessionVariables.DOOMWADDIR;
    };
    expected = {
      doom = { inherit (doom) iwad wadsDir; };
      wadDir = dirOf doom.iwad;
    };
  };
}
