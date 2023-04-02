{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.shell.gnupg;
in {
  options.modules.shell.gnupg = with types; {
    enable   = mkBoolOpt false;
    cacheTTL = mkOpt int 3600;  # 1hr
  };

  config = mkIf cfg.enable {
    env.GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
    systemd.user.services.gpg-agent.serviceConfig.Environment = [
      "GNUPGHOME=/home/${config.user.name}/.config/gnupg"
    ];

    programs.gnupg.agent = {
      enable = true;
      pinentryFlavor = "gtk2";
    };

    home.configFile."gnupg/gpg-agent.conf".text = ''
      default-cache-ttl ${toString cfg.cacheTTL}
    '';
  };
}
