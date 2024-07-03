{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.dev;
in {
  options.modules.dev = {
    xdg.enable = mkBoolOpt config.modules.xdg.enable;
  };

  config = mkIf cfg.xdg.enable {
    # TODO
  };
}
