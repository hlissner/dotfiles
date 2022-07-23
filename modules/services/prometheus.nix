# modules/services/prometheus.nix
#
# For keeping an eye on things...

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
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
