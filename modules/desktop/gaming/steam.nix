{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.gaming.steam;
in {
  options.modules.desktop.gaming.steam = with types; {
    enable = mkBoolOpt false;
    hardware.enable = mkBoolOpt false;
    libDir = mkOpt str "$XDG_DATA_HOME/steamlib";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.steam.enable = true;

      # better for steam proton games
      systemd.extraConfig = "DefaultLimitNOFILE=1048576";
    }

    (mkIf cfg.hardware.enable {
      hardware.steam-hardware.enable = true;
    })
  ]);
}
