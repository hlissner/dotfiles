{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.media.ncmpcpp;
in {
  options.modules.desktop.media.ncmpcpp = {
    enable = mkBoolOpt false;
    # modipy.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (ncmpcpp.override { visualizerSupport = true; })
    ];

    environment.variables.NCMPCPP_HOME = "$XDG_CONFIG_HOME/ncmpcpp";

    # Symlink these one at a time because ncmpcpp writes other files to
    # ~/.config/ncmpcpp, so it needs to be writeable.
    home.configFile = {
      "ncmpcpp/config".source   = "${self.configDir}/ncmpcpp/config";
      "ncmpcpp/bindings".source = "${self.configDir}/ncmpcpp/bindings";
    };
  };
}
