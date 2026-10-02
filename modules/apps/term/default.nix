{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.term;
in {
  options.modules.apps.term = {
    default = mkOpt types.str "xterm";
  };

  config = {
    environment.sessionVariables.TERMINAL = cfg.default;
  };
}
