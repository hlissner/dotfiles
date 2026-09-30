{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.media.music;
in {
  options.modules.apps.media.music = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      feishin        # media player
      beets          # library management
      playerctl      # to control feishen
      yt-dlp
      picard         # for editing tags
      rsgain
      shntool
      cuetools
      flac
      spek           # spectrum analysis
    ];

    home.configLink."beets/config.yaml" = "${config.hey.configDir}/beets/config.yaml";
  };
}
