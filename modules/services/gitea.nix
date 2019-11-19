{ config, lib, pkgs, ... }:

{
  users.users.git = {
    useDefaultShell = true;
    home = "/var/lib/gitea";
    group = "gitea";
  };

  services.gitea = {
    enable = true;
    log.level = "Info";

    appName = "V-NOUGHT";
    database = {
      user = "git";
      type = "postgres";
    };
    domain = "v0.io";
    rootUrl = "https://git.v0.io/";
    cookieSecure = true;
    useWizard = false;
    disableRegistration = true;
    extraConfig = ''
      [server]
      SSH_DOMAIN = v0.io
    '';
  };
}
