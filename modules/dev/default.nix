{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.dev;
in {
  options.modules.dev = {
    xdg.enable = mkBoolOpt config.xdg.enable;
  };

  config = mkIf cfg.xdg.enable {
    # TODO
  };
}
