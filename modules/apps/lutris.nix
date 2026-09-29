# modules/apps/lutris.nix

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.lutris;
in {
  options.modules.apps.lutris = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
    ];

    # Better for steam proton games
    systemd.user.settings.Manager.DefaultLimitNOFILE = mkDefault 1048576;
  };
}
