{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.gitea;
in {
  options.modules.services.gitea = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # I prefer git@... ssh addresses over gitea@...
    users.users.git = {
      useDefaultShell = true;
      home = "/var/lib/gitea";
      group = "gitea";
    };

    services.gitea = {
      enable = true;
      log.level = "Info";

      user = "git";
      database = {
        user = "git";
        type = "postgres";
      };
      useWizard = false;
      disableRegistration = true;

      # We're assuming SSL-only connectivity
      cookieSecure = true;
    };
  };
}
