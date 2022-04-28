{ config, lib, pkgs, ... }:

{
  modules.services.cgit = {
    enable = true;
    domain = "git.henrik.io";
  };

  services.nginx.virtualHosts."git.henrik.io" = {
    http2 = true;
    forceSSL = true;
    enableACME = true;
  };
}
