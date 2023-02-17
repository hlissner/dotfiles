# modules/dev/java.nix --- Poster child for carpal tunnel
#
# TODO

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.java;
in {
  options.modules.dev.java = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # TODO
    })

    (mkIf cfg.xdg.enable {
      env._JAVA_OPTIONS = "-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME\"/java";
    })
  ];
}
