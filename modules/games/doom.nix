# modules/games/doom.nix --- GZDoom, Steam's Doom 2, and a menu over my pk3s
#
# Brutal Doom and friends aren't in nixpkgs and can't be fetched: ModDB serves
# downloads through mirror redirects with nothing stable to pin. So the pk3s
# sit in wadsDir and `hey @rofi doommenu` picks one at launch time; nix only
# tells it where to look.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.games.doom;
    steam = config.modules.games.steam;
in {
  options.modules.games.doom = with types; {
    enable = mkBoolOpt false;
    # Steam's classic Doom 2 (app 2300). The 2024 "DOOM + DOOM II" re-release
    # (app 2280) lays its WADs out differently; point this at one of those if
    # that's what gets installed.
    iwad = mkOpt str "${steam.libraryDir}/steamapps/common/Doom 2/base/DOOM2.WAD";
    # Where the pk3s and pwads are. Nothing here creates or fills it.
    wadsDir = mkOpt str "${config.home.dataDir}/games/doom";
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.gzdoom ]
      ++ optional config.modules.apps.rofi.enable
           (mkLauncherEntry "Launch Doom ->" {
             icon = "gzdoom";
             exec = "hey @rofi doommenu";
             categories = [ "Game" ];
           });

    hey.info.doom = { inherit (cfg) iwad wadsDir; };

    # The menu passes -iwad itself; this is for a bare `gzdoom`.
    environment.sessionVariables.DOOMWADDIR = dirOf cfg.iwad;
  };
}
