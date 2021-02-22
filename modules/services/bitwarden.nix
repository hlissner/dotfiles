{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.bitwarden;
in {
  options.modules.services.bitwarden = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.bitwarden_rs = {
      enable = true;
      backupDir = "/run/backups/bitwarden_rs";
    };

    user.extraGroups = [ "bitwarden_rs" ];

    services.fail2ban.jails.bitwarden_rs = ''
      enabled = true
      filter = bitwarden_rs
      port = 80,443,8002
      maxretry = 5
    '';
  };
}
