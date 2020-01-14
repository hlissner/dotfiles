# FIXME

{ config, lib, pkgs, ... }:
{
  imports = [
    <my/modules/linode.nix>
  ];

  networking.hostName = "holo";
  time.timeZone = "America/Toronto";

  services.nginx = {
    # user = config.my.username;
    virtualHosts = {
      # "domain.com" = {
      #   default = true;
      #   enableACME = true;
      #   forceSSL = true;
      #   root = "...";
      # };
    };
  };
}
