# Ao -- my home development and user-facing server

{ config, lib, pkgs, ... }:

with lib.my;
{
  imports = [
    ../server.nix
    ../home.nix
    ./hardware-configuration.nix

    # TODO
    ./modules/wireguard.nix
    ./modules/dyndns.nix

    # Services
    # ./modules/backup.nix
    # ./modules/gitea.nix
    ./modules/cgit.nix
    ./modules/vaultwarden.nix
    ./modules/shlink.nix
    ./modules/metrics.nix
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

  systemd.tmpfiles.rules = [
    "z /backup 777 root root - -"
    "d /backup 777 root root - -"
  ];

  ## Local config
  time.timeZone = "Europe/Copenhagen";
  networking.networkmanager.enable = true;
  security.acme.defaults.email = "acme@accounts.henrik.io";
  # security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

  ## Shared nginx settings
  services.geoipupdate = {
    enable = true;
    settings = {
      AccountID = 636144;
      EditionIDs = ["GeoLite2-ASN" "GeoLite2-City" "GeoLite2-Country"];
      LicenseKey = config.age.secrets.geolite-apikey.path;
    };
  };

  services.nginx = {
    # Make it easier to whitelist by country on some virtualhosts
    additionalModules = [ pkgs.nginxModules.geoip2 ];
    commonHttpConfig = ''
      geoip2 ${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-Country.mmdb {
        $geoip2_data_country_code country iso_code;
      }
      map $geoip2_data_country_code $deny {
        default 1;
        DK 0;
        CA 0;
      }
    '';

    # nginx hosts
    virtualHosts."home.lissner.net" = {
      serverAliases = [ "home2.lissner.net" ];
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
  };

}
