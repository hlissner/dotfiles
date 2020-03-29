# Ao -- my home development and user-facing server

{ pkgs, config, lib, ... }:
{
  imports = [
    ../personal.nix
    ./hardware-configuration.nix
  ];

  modules = {
    shell.git.enable = true;
    shell.zsh.enable = true;
    services.ssh.enable = true;
    services.nginx.enable = true;
    services.gitea.enable = true;
    services.syncthing.enable = true;
  };

  my.zsh.rc = lib.readFile <modules/themes/aquanaut/zsh/prompt.zsh>;

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";

  # nginx hosts
  services.nginx = {
    user = config.my.username;
    virtualHosts = {
      "v0.io" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        root = "/home/${config.my.username}/www/v0.io";
      };
      "dl.v0.io" = {
        enableACME = true;
        addSSL = true;
        root = "/home/${config.my.username}/www/dl.v0.io";
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
      "tv.v0.io" = {
        http2 = true; # more performant for streaming
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          add_header Content-Security-Policy "default-src https: data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com/cv/js/sender/v1/cast_sender.js; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'self'";

          # Some players don't reopen a socket and playback stops totally
          # instead of resuming after an extended pause
          send_timeout 100m;

          # Intentionally not hardened for security for player support and
          # encryption video streams has a lot of overhead with something like
          # AES-256-GCM-SHA384.
          ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';

          ssl_stapling on;
          ssl_stapling_verify on;

          # Forward real ip and host to Plex
          proxy_set_header Referer $server_addr;
          proxy_set_header Origin $server_addr;

          # Security / XSS Mitigation Headers
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-XSS-Protection "1; mode=block";
          add_header X-Content-Type-Options "nosniff";
        '';
        # locations."= /".return = "302 https://tv.v0.io/web/index.html";
        locations."/socket" = {
          proxyPass = "http://192.168.1.13:8096";
          proxyHttpVersion = "1.1";
          # Buffering off send to the client as soon as the data is received
          # from JellyFin.
          proxyBuffering = "off";
        };
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://192.168.1.13:8096";
        };
      };
    };
  };

  security.acme.certs = {
    "v0.io".email = config.my.email;
    "dl.v0.io".email = config.my.email;
    "git.v0.io".email = config.my.email;
    "tv.v0.io".email = config.my.email;
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

  services.fail2ban = {
    enable = true;
    jails.DEFAULT = ''
      ignoreip = 127.0.0.1/8,192.168.1.0/24
      bantime = 3600
      maxretry = 5
    '';
    jails.sshd = ''
      filter = sshd
      action = iptables[name=ssh, port=22, protocl=tcp]
      enabled = true
    '';
  };
}
