{ config, lib, ... }:

{
  modules.services.gitea.enable = true;

  services.gitea = {
    appName = "V-NOUGHT";
    domain = "v0.io";
    rootUrl = "https://git.v0.io/";
    disableRegistration = false;
    settings = {
      server.SSH_DOMAIN = "v0.io";
      mailer = {
        ENABLED = true;
        FROM = "mail@v0.io";
        HOST = "mail.gmail.com:465";
        USER = "hlissner@gmail.com";
        MAILER_TYPE = "smtp";
        IS_TLS_ENABLED = "true";
      };
    };
    mailerPasswordFile = config.age.secrets.gitea-smtp.path;
    database.type = "sqlite3";
  };

  services.nginx.virtualHosts."git.v0.io" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
