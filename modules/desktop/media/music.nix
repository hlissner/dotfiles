{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.music;
in {
  options.modules.desktop.media.music = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      unstable.feishin  # media player
      beets          # library management
      playerctl      # to control feishen
      yt-dlp
      picard         # for editing tags
      id3v2          # for editing tags (CLI)

      r128gain
      shntool
      cuetools
      flac
    ];

    home.configFile = {
      "beets" = {
        source = "${hey.configDir}/beets";
        recursive = true;
      };
    };
  };
}
