# Ao -- my home development server

{ config, ... }:

{
  imports = [
    ./.  # import common settings

    ./modules/services/ssh.nix
    ./modules/services/nginx.nix
    ./modules/services/gitea.nix
    ./modules/services/syncthing.nix

    ./modules/shell/git.nix
    ./modules/shell/zsh.nix
  ];

  networking.hostName = "ao";
  networking.networkmanager.enable = true;

  # syncthing
  services.syncthing.guiAddress = "192.168.1.10:8384";
  networking.firewall.allowedTCPPorts = [ 8384 ];

  # nginx hosts
  services.nginx = {
    user = "hlissner";
    virtualHosts = {
      "v0.io" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        root = "/var/www/v0.io";
      };
      "dl.v0.io" = {
        enableACME = true;
        addSSL = true;
        root = "/var/www/dl.v0.io";
        locations."~* \.(?:ico|css|js|gif|jpe?g|png|mp4)$".extraConfig = ''
          expires 30d;
          add_header Pragma public;
          add_header Cache-Control public;
        '';
      };
      "git.v0.io" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = http://127.0.0.1:3000;
      };
    };
  };

  security.acme.certs = {
    "v0.io".email = "henrik@lissner.net";
    "dl.v0.io".email = "henrik@lissner.net";
    "git.v0.io".email = "henrik@lissner.net";
  };
}
