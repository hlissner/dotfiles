{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.browsers;
in {
  options.modules.apps.browsers = {
    default = mkOpt (with types; nullOr str) null;
  };

  config = mkIf (cfg.default != null) {
    environment.sessionVariables.BROWSER = cfg.default;
  };
}
