{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.calibre;
in {
  options.modules.services.calibre = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.calibre-server.enable = true;

    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
