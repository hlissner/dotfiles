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
    };

    user.extraGroups = [ "gitea" ];

    services.gitea = {
      enable = true;

      user = "git";
      database.user = "git";

      # We're assuming SSL-only connectivity
      cookieSecure = true;
      # Only log what's important
      log.level = "Info";
      settings.server.DISABLE_ROUTER_LOG = true;
    };

    services.fail2ban.jails.gitea = ''
      enabled = true
      filter = gitea
      logpath = ${config.services.gitea.log.rootPath}/gitea.log
      bantime = 1800
      findtime = 3600
      banaction = %(banaction_allports)s
    '';

    modules.backup.targets.gitea = {
      baseDir = config.users.users.git.home;
      owner = "git";
      targets = [ "repositories" "data" ];
      suspendServices = [ "gitea" ];
    };
  };
}
