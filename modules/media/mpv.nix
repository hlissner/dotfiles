{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.media.mpv = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.media.mpv.enable {
    my.packages = with pkgs; [
      mpv-with-scripts
      mpvc  # CLI controller for mpv
      (mkIf config.services.xserver.enable
        celluloid)  # nice GTK GUI for mpv
    ];
  };
}
