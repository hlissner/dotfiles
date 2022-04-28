# Ao -- my home development and user-facing server

{ config, lib, ... }:

with lib.my;
{
  imports = [
    ../server.nix
    ../home.nix
    ./hardware-configuration.nix

    ./modules/backup.nix
    # ./modules/gitea.nix
    ./modules/cgit.nix
    ./modules/vaultwarden.nix
    ./modules/shlink.nix
  ];


  ## Modules
  modules = {
    shell = {
      direnv.enable = true;
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
  security.acme.defaults.email = "accounts+acme@henrik.io";
  # security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

  # nginx hosts
  services.nginx.virtualHosts."home.lissner.net" = {
    default = true;
    http2 = true;
    forceSSL = true;
    enableACME = true;
    root = "/srv/www/home.lissner.net";
    # extraConfig = ''
    #   client_max_body_size 10m;
    #   proxy_buffering off;
    #   proxy_redirect off;
    # '';
    # locations."/".proxyPass = "http://kiiro:8000";
  };
}
