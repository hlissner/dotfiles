{ config, lib, ... }:

{
  modules.services.bitwarden.enable = true;

  services.bitwarden_rs.config = {
    signupsAllowed = false;
    invitationsAllowed = true;
    domain = "https://p.v0.io";
    httpPort = 8002;
  };

  # Inject secrets at runtime
  systemd.services.bitwarden_rs.serviceConfig = {
    EnvironmentFile = [ config.age.secrets.bitwarden-smtp-env.path ];
    Restart = "on-failure";
    RestartSec = "2s";
  };

  services.nginx.virtualHosts."p.v0.io" = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      client_max_body_size 128M;
    '';
    locations = {
      "/".proxyPass = "http://127.0.0.1:8000";
      "/notifications/hub".proxyWebsockets = true;
      "/notifications/hub/negotiate".proxyPass = "http://127.0.0.1:8001";
    };
  };
}
