# modules/services/prometheus.nix
#
# For keeping an eye on things...

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.services.prometheus;
in {
  options.modules.services.prometheus = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
    };
  };
}
