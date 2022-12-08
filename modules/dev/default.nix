{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev;
in {
  options.modules.dev = {
    xdg.enable = mkBoolOpt config.xdg.enable;
  };

  config = mkIf cfg.xdg.enable {
    # TODO
  };
}
