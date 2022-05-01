{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.fail2ban;
in {
  options.modules.services.fail2ban = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      ignoreIP = [ "127.0.0.1/16" "192.168.1.0/24" ];
      banaction-allports = "iptables-allports";
      bantime-increment = {
        enable = true;
        maxtime = "168h";
        factor = "4";
      };
      jails.DEFAULT = ''
        blocktype = DROP
        bantime = 1h
        findtime = 1h
      '';
    };

    # Extra filters
    environment.etc = {
      "fail2ban/filter.d/gitea.conf".text = ''
        [Definition]
        failregex =  .*(Failed authentication attempt|invalid credentials|Attempted access of unknown user).* from <HOST>
        ignoreregex =
        journalmatch = _SYSTEMD_UNIT=gitea.service
      '';
    };
  };
}
