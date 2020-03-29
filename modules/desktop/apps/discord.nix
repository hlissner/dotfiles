{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.apps.discord = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.apps.discord.enable {
    my.packages = with pkgs; [
      discord
      # ripcord
    ];
  };
}
