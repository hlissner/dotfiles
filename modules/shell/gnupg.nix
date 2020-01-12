{ config, lib, pkgs, ... }:

{
  my = {
    packages = with pkgs; [
      gnupg
      pinentry
    ];
    env.GNUPGHOME = "$XDG_CONFIG_HOME/gnupg";
    init = "mkdir -p \"$GNUPGHOME\" -m 700";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  systemd.user.services.gpg-agent.serviceConfig.ExecStart = [
    "" ''
       ${pkgs.gnupg}/bin/gpg-agent \
            --supervised \
            --allow-emacs-pinentry \
            --default-cache-ttl 1800 \
            --pinentry-program ${pkgs.pinentry}/bin/pinentry-gtk-2
       ''
  ];
}
