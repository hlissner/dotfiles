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
      unstable.beets          # library management
      hey.packages.feishin    # REVIEW: NixOS/nixpkgs#445926
      playerctl               # to control feishen
      unstable.yt-dlp
      picard                  # for editing tags
      unstable.id3v2          # for editing tags (CLI)
    ];

    home.configFile = {
      "beets" = {
        source = "${hey.configDir}/beets";
        recursive = true;
      };
    };
  };
}
