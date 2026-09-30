# modules/apps/flatpak.nix
#
# For the software that won't be packaged for nix, and the software I'd rather
# keep at arm's length from the rest of the system.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.flatpak;
in {
  options.modules.apps.flatpak = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      package = mkIf config.modules.xdg.enable
        # Respect XDG, damn it!
        (mkWrapper pkgs.flatpak ''
          wrapProgram "$out/bin/flatpak" \
            --run 'export HOME="''${XDG_FAKE_HOME:-$HOME}"'
        '');
    };

    systemd.services.hey-flatpak-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ config.services.flatpak.package ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
