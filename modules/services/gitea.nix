{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.gitea = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.gitea.enable {
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
