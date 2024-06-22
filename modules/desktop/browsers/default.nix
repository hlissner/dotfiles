{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.browsers;
in {
  options.modules.desktop.browsers = {
    default = mkOpt (with types; nullOr str) null;
  };

  config = mkIf (cfg.default != null) {
    environment.sessionVariables.BROWSER = cfg.default;
  };
}
