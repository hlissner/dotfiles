{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.scala;
in {
  options.modules.dev.scala = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        scala
        jdk
        sbt
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
