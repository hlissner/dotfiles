{ config, options, lib, pkgs, my, ... }:

with lib;
with lib.my;
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
