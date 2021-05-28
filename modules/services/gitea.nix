# modules/services/gitea.nix
#
# Gitea is essentially a self-hosted github. This modules configures it with the
# expectation that it will be served over an SSL-secured reverse proxy (best
# paired with my modules.services.nginx module).
#
# Resources
#   Config: https://docs.gitea.io/en-us/config-cheat-sheet/
#   API:    https://docs.gitea.io/en-us/api-usage/

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.gitea;
in {
  options.modules.services.gitea = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Allows git@... clone addresses rather than gitea@...
    users.users.git = {
      useDefaultShell = true;
      home = "/var/lib/gitea";
      group = "gitea";
      isSystemUser = true;
    };

    user.extraGroups = [ "gitea" ];

    services.gitea = {
      enable = true;
      lfs.enable = true;

      user = "git";
      database.user = "git";

      # We're assuming SSL-only connectivity
      cookieSecure = true;
      # Only log what's important, but Info is necessary for fail2ban to work
      log.level = "Info";
      settings = {
        server.DISABLE_ROUTER_LOG = true;
        database.LOG_SQL = false;
        service.ENABLE_BASIC_AUTHENTICATION = false;
      };

      dump.interval = "daily";
    };

    services.fail2ban.jails.gitea = ''
      enabled = true
      filter = gitea
      banaction = %(banaction_allports)s
      maxretry = 5
    '';
  };
}
