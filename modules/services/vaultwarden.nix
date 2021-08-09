{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.vaultwarden;
in {
  options.modules.services.vaultwarden = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.vaultwarden.enable = true;

    user.extraGroups = [ "vaultwarden" ];

    services.fail2ban.jails.vaultwarden = ''
      enabled = true
      filter = vaultwarden
      port = 80,443,8002
      maxretry = 5
    '';
  };
}
