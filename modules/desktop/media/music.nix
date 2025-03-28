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
      (ncmpcpp.override { visualizerSupport = true; })
      beets    # library management
      yt-dlp
      mpc
    ];

    environment.variables.NCMPCPP_HOME = "$XDG_CONFIG_HOME/ncmpcpp";

    home.configFile = {
      "beets" = {
        source = "${hey.configDir}/beets";
        recursive = true;
      };
      "ncmpcpp" = {
        source    = "${hey.configDir}/ncmpcpp";
        recursive = true;
      };
    };
  };
}
