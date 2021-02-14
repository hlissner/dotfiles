# Ao -- my home development and user-facing server

{ config, lib, ... }:

with lib.my;
{
  imports = [
    ../personal.nix
    ./hardware-configuration.nix

    ./modules/gitea.nix
    ./modules/bitwarden.nix
  ];


  ## Modules
  modules = {
    shell = {
      git.enable = true;
      zsh.enable = true;
    };
    services = {
      fail2ban.enable = true;
      ssh.enable = true;
      nginx.enable = true;
    };

    theme.active = "alucard";
  };


  ## Local config
  networking.networkmanager.enable = true;

  # nginx hosts
  services.nginx.virtualHosts."v0.io" = {
    default = true;
    forceSSL = true;
    enableACME = true;
    locations."~* \.(?:ico|css|map|js|gif|jpe?g|png|ttf|woff)$".extraConfig = ''
      access_log off;
      expires 30d;
      add_header Pragma public;
      add_header Cache-Control "public, mustrevalidate, proxy-revalidate";
      proxy_pass https://kiiro:8001;
      proxy_buffering off;
    '';
    locations."/".extraConfig = ''
      client_max_body_size 10m;
      proxy_ssl_server_name on;
      proxy_pass_header Authorization;
      proxy_pass https://kiiro:8001;
      proxy_buffering off;
    '';
  };

  security.acme.email = "henrik@lissner.net";
}
