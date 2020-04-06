{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.modules;
    gnupgCfg = cfg.shell.gnupg;
in {
  options.modules.shell.gnupg = {
    enable = mkOption { type = types.bool; default = false; };
    cacheTTL = mkOption { type = types.int; default = 1800; };
  };

  config = mkIf gnupgCfg.enable {
    my = {
      packages = with pkgs; [
        gnupg
        pinentry
      ];
      env.GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
    };

    system.activationScripts.setupGnuPG = "mkdir -p \"${config.my.env.GNUPGHOME}\" -m 700";

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    systemd.user.services.gpg-agent.serviceConfig.ExecStart = [
      "" ''
         ${pkgs.gnupg}/bin/gpg-agent \
              --supervised \
              --allow-emacs-pinentry \
              --default-cache-ttl ${toString gnupgCfg.cacheTTL} \
              --pinentry-program ${pkgs.pinentry}/bin/pinentry-gtk-2
         ''
    ];
  };
}
