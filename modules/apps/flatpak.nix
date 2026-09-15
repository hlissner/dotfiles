# modules/apps/flatpak.nix
#
# For the software that won't be packaged for nix, and the software I'd rather
# keep at arm's length from the rest of the system.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.apps.flatpak;
in {
  options.modules.apps.flatpak = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;
    };

    systemd.services.flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
