{ config, options, lib, pkgs, ... }:

with builtins;
with lib;
with lib.my;
let cfg = config.modules.X.Y;
in {
  options.modules.X.Y = {
    enable = mkBoolOpt false;
  };

  config = cfg.enable {

  };
}
