{ self, lib, config, options, ... }:

with lib;
with self.lib;
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
