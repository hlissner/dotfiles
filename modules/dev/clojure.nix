# modules/dev/clojure.nix --- https://clojure.org/
#
# I don't use clojure... yet.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.clojure;
in {
  options.modules.dev.clojure = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        clojure
        joker
        leiningen
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
