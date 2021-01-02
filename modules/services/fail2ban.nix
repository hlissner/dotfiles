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
      jails.DEFAULT = ''
        blocktype = DROP
        bantime = 7200
        findtime = 7200
      '';
    };

    # Extra filters
    environment.etc = {
      "fail2ban/filter.d/bitwarden_rs.conf".text = ''
        [INCLUDES]
        before = common.conf

        [Definition]
        failregex = ^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
        ignoreregex =
      '';
      "fail2ban/filter.d/gitea.conf".text = ''
        [Definition]
        failregex =  .*(Failed authentication attempt|invalid credentials|Attempted access of unknown user).* from <HOST>
        ignoreregex =
      '';
    };
  };
}
