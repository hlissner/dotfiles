{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.gaming.steam;
    steamDir = "$XDG_STATE_HOME/steam";
in {
  options.modules.desktop.gaming.steam = with types; {
    enable = mkBoolOpt false;
    mangohud.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable {
    programs = {
      steam.enable = true;
      gamemode.enable = true;
    };

    # Stop Steam from polluting $HOME
    environment.systemPackages = with pkgs; [
      (writeScriptBin "steam" ''
        #!${stdenv.shell}
        HOME="${steamDir}" exec ${pkgs.gamemode}/bin/gamemode ${config.programs.steam.package}/bin/steam "$@"
      '')
      # for running GOG and humble bundle games
      (writeScriptBin "steam-run" ''
        #!${stdenv.shell}
        HOME="${steamDir}" exec ${pkgs.gamemode}/bin/gamemode ${config.programs.steam.package.run}/bin/steam-run "$@"
      '')
    ] ++ (if cfg.mangohud.enable then [ pkgs.mangohud ] else []);

    # better for steam proton games
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  };
}
