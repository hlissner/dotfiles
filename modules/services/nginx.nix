{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.nginx;
in {
  options.modules.services.nginx = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    user.extraGroups = [ "nginx" ];

    services.nginx = {
      enable = true;

      # Use recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };
}
