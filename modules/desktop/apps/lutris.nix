# modules/desktop/apps/steam.nix

{ hey, heyBin, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.lutris;
in {
  options.modules.desktop.apps.lutris = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.lutris
    ];

    # Better for steam proton games
    systemd.extraConfig = mkDefault "DefaultLimitNOFILE=1048576";
  };
}
