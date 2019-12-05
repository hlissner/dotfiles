{ config, lib, pkgs, ... }:

{
  environment = {
    extraInit = ''
      export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
      mkdir -p "$GNUPGHOME" -m 700
    '';

    systemPackages = with pkgs; [
      gnupg
      pinentry
    ];
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
            --default-cache-ttl 1200 \
            --pinentry-program ${pkgs.pinentry}/bin/pinentry-gtk-2
       ''
  ];
}
