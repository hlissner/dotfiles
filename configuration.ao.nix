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

  time.timeZone = "America/Toronto";

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
      "plex.v0.io" = {
        http2 = true; # more performant for streaming
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          # Some players don't reopen a socket and playback stops totally
          # instead of resuming after an extended pause
          send_timeout 100m;

          # Intentionally not hardened for security for player support and
          # encryption video streams has a lot of overhead with something like
          # AES-256-GCM-SHA384.
          ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';

          # Forward real ip and host to Plex
          proxy_set_header Referer $server_addr;
          proxy_set_header Origin $server_addr;

          # Nginx default client_max_body_size is 1MB, which breaks Camera
          # Upload feature from the phones. Increasing the limit fixes the
          # issue. Anyhow, if 4K videos are expected to be uploaded, the size
          # might need to be increased even more
          client_max_body_size 100M;

          # Plex headers
          proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
          proxy_set_header X-Plex-Device $http_x_plex_device;
          proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
          proxy_set_header X-Plex-Platform $http_x_plex_platform;
          proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
          proxy_set_header X-Plex-Product $http_x_plex_product;
          proxy_set_header X-Plex-Token $http_x_plex_token;
          proxy_set_header X-Plex-Version $http_x_plex_version;
          proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
          proxy_set_header X-Plex-Provides $http_x_plex_provides;
          proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
          proxy_set_header X-Plex-Model $http_x_plex_model;

          # Buffering off send to the client as soon as the data is received
          # from Plex.
          proxy_buffering off;
        '';
        locations."= /".return = "302 https://plex.v0.io/web/index.html";
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://192.168.1.13:32400";
        };
      };
    };
  };

  security.acme.certs = {
    "v0.io".email = "henrik@lissner.net";
    "dl.v0.io".email = "henrik@lissner.net";
    "git.v0.io".email = "henrik@lissner.net";
    "plex.v0.io".email = "henrik@lissner.net";
  };

  services.gitea = {
    appName = "V-NOUGHT";
    domain = "v0.io";
    rootUrl = "https://git.v0.io/";
    extraConfig = ''
      [server]
      SSH_DOMAIN = v0.io
    '';
  };
}
