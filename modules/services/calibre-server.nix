{ config, lib, pkgs, ... }:

{
  services.calibre-server.enable = true;
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
