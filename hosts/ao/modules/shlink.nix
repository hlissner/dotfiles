{ config, lib, pkgs, ... }:

with builtins;
{
  modules.services.docker.enable = true;

  docker-containers."shlink" = {
    image = "shlinkio/shlink:stable";
    environment = {
      "DEFAULT_DOMAIN" = "henrik.link";
      "USE_HTTPS" = "false";
    };
    ports = [ "8080:8080" ];
    volumes = [];
  };

  services.nginx.virtualHosts."henrik.link" = {
    default = true;
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:8080";
  };
}
