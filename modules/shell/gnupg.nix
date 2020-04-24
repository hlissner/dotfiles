{ config, options, lib, pkgs, ... }:

with lib;
let cfg = config.modules;
    gnupgCfg = cfg.shell.gnupg;
    homedir = "$XDG_CONFIG_HOME/gnupg";
in {
  options.modules.shell.gnupg = {
    enable = mkOption { type = types.bool; default = false; };
    cacheTTL = mkOption { type = types.int; default = 1800; };
  };

  config = mkIf gnupgCfg.enable {
    my = {
      env.GNUPGHOME = homedir;

      # HACK Without this config file you get "No pinentry program" on 20.03.
      #      program.gnupg.agent.pinentryFlavor doesn't appear to work, and this
      #      is cleaner than overriding the systemd unit.
      home.xdg.configFile."gnupg/gpg-agent.conf" = {
        text = ''
          enable-ssh-support
          allow-emacs-pinentry
          default-cache-ttl ${toString gnupgCfg.cacheTTL}
          pinentry-program ${pkgs.pinentry.gtk2}/bin/pinentry
        '';
      };
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
