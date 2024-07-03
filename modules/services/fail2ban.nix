{ hey, lib, config, options, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.fail2ban;
in {
  options.modules.services.fail2ban = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      ignoreIP = [ "127.0.0.1/16" "192.168.0.0/16" ];
      bantime = "1h";
      bantime-increment = {
        enable = true;
        maxtime = "168h";
        factor = "4";
      };
      jails.DEFAULT.settings = {
        blocktype = "DROP";
        findtime = "1h";
      };
    };

    # Extra filters
    # environment.etc = {
    #   "fail2ban/filter.d/gitea.conf".text = ''
    #     [Definition]
    #     failregex =  .*(Failed authentication attempt|invalid credentials|Attempted access of unknown user).* from <HOST>
    #     ignoreregex =
    #     journalmatch = _SYSTEMD_UNIT=gitea.service
    #   '';
    # };
  };
}
