{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev;
in {
  options.modules.dev = {
    xdg.enable = mkBoolOpt true;
  };

  config = mkIf cfg.xdg.enable {
    # TODO
  };
}
