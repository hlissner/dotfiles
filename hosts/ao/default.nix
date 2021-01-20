# Ao -- my home development and user-facing server

{ config, lib, ... }:

with lib.my;
{
  imports = [
    ../personal.nix
    ./hardware-configuration.nix

    # ./modules/postgresql.nix
    ./modules/gitea.nix
    ./modules/bitwarden.nix
    # ./modules/tinytinyrss.nix
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
    locations."/".extraConfig = ''
      proxy_pass https://kiiro:8001;
      proxy_ssl_server_name on;
      proxy_pass_header Authorization;
    '';
  };

  security.acme.email = "henrik@lissner.net";
}
