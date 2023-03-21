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
      # Don't specify any pinentry flavor in the gpg-agent's service, otherwise
      # it could potentially overwrite our dotfiles.
      pinentryFlavor = null;
    };

    # HACK: Passing GTK2_RC_FILES to the service's Environment didn't work. And
    #   setting GTK2_RC_FILES globally in
    #   services.xserver.displayManager.sessionCommands is too nuclear an
    #   option. This is a clumsy workaround, but is the most targeted.
    home.configFile."gnupg/gpg-agent.conf" = {
      text = ''
        default-cache-ttl ${toString cfg.cacheTTL}
        pinentry-program ${pkgs.writeShellScriptBin "pinentry" ''
          GTK2_RC_FILES=/etc/xdg/gtk-2.0/gtkrc exec ${pkgs.pinentry.gtk2}/bin/pinentry
        ''}/bin/pinentry
      '';
    };
  };
}
