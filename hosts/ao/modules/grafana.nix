{ config, lib, pkgs, ... }:

{
  services.grafana = {
    enable = true;
    port = 3001;
  };

  services.nginx.virtualHosts."grafana.henrik.io" = {
    http2 = true;
    forceSSL = true;
    enableACME = true;
    extraConfig = ''if ($deny) { return 503; }'';
    locations."/".proxyPass = "http://127.0.0.1:3001";
  };
}
