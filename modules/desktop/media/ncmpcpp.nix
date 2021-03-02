{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.ncmpcpp;
    configDir = config.dotfiles.configDir;
in {
  options.modules.desktop.media.ncmpcpp = {
    enable = mkBoolOpt false;
    # modipy.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (ncmpcpp.override { visualizerSupport = true; })
    ];

    env.NCMPCPP_HOME = "$XDG_CONFIG_HOME/ncmpcpp";

    # Symlink these one at a time because ncmpcpp writes other files to
    # ~/.config/ncmpcpp, so it needs to be writeable.
    home.configFile = {
      "ncmpcpp/config".source   = "${configDir}/ncmpcpp/config";
      "ncmpcpp/bindings".source = "${configDir}/ncmpcpp/bindings";
    };
  };
}
