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

    services.fail2ban.jails = {
      vaultwarden = ''
        enabled = true
        filter = vaultwarden
        port = 80,443,8000
        maxretry = 5
      '';
      vaultwarden-admin = ''
        enabled = true
        port = 80,443
        filter = vaultwarden-admin
        maxretry = 3
        bantime = 14400
        findtime = 14400
      '';
    };

    environment.etc = {
      "fail2ban/filter.d/vaultwarden.conf".text = ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
        ignoreregex =
        journalmatch = _SYSTEMD_UNIT=vaultwarden.service
      '';
      "fail2ban/filter.d/vaultwarden-admin.conf".text = ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*Invalid admin token\. IP: <ADDR>.*$
        ignoreregex =
        journalmatch = _SYSTEMD_UNIT=vaultwarden.service
      '';
    };
  };
}
