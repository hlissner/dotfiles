# modules/services/gnome-keyring.nix --- org.freedesktop.secrets, for apps
# that insist on a keyring (Supersonic)
#
# Not the GNOME stack: gnome-keyring and gcr are the only new store paths.
# D-Bus activates the daemon the first time something asks for a secret, and
# the PAM hook unlocks the login keyring with the greetd password, so I never
# see a prompt. nixpkgs only hooks the `login` service; the greeter is where
# the password actually gets typed.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.services.gnome-keyring;
    sshEnabled = config.modules.services.ssh.enable;
in {
  options.modules.services.gnome-keyring = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    # On by default whenever the keyring is, and it refuses to coexist with
    # programs.ssh.startAgent. gcr wraps ssh-agent and stashes passphrases in
    # the keyring. It only preloads ~/.ssh, so keys under ~/.config/ssh
    # appear after an ssh-add, once.
    services.gnome.gcr-ssh-agent.enable = sshEnabled;
    programs.ssh.startAgent = mkIf sshEnabled false;
    # The socket unit exports this into the systemd user session; tty and ssh
    # logins need it from the shell side too.
    environment.sessionVariables.SSH_AUTH_SOCK = mkIf sshEnabled "$XDG_RUNTIME_DIR/gcr/ssh";
  };
}
