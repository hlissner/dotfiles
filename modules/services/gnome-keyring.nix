# modules/services/gnome-keyring.nix --- org.freedesktop.secrets

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.services.gnome-keyring;
    sshEnabled = config.modules.services.ssh.enable;
in {
  options.modules.services.gnome-keyring = with types; {
    enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;
      services.gnome.gcr-ssh-agent.enable = sshEnabled;
    })

    # nixpkgs' niri module switches the keyring on by itself, so this can't be
    # gated behind cfg.enable.
    (mkIf config.services.gnome.gcr-ssh-agent.enable {
      programs.ssh.startAgent = false;
      environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    })
  ];
}
