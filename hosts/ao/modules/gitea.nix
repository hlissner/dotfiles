{ config, lib, ... }:

{
  modules.services.gitea.enable = true;

  services.gitea = {
    appName = "V-NOUGHT";
    domain = "v0.io";
    rootUrl = "https://git.v0.io/";
    disableRegistration = true;
    settings = {
      server.SSH_DOMAIN = "v0.io";
      mailer = {
        ENABLED = true;
        FROM = "git@v0.io";
        HOST = "smtp.mailgun.org:587";
        USER = config.age.secrets.mailgun-smtp-username.path;
        MAILER_TYPE = "smtp";
      };
    };
    mailerPasswordFile = config.age.secrets.mailgun-smtp-secret.path;
  };

  services.nginx.virtualHosts."git.v0.io" = {
    forceSSL = true;
    enableACME = true;
    root = "/srv/www/git.v0.io";
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
