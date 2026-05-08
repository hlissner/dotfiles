{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.quickshell;
in {
  options.modules.desktop.quickshell = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.unstable.dms;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.unstable; [
      cfg.package
      quickshell
      matugen
      kdePackages.qtimageformats
      kdePackages.kirigami
      adwaita-icon-theme
    ];

    systemd.user.services.dms = {
      description = "DMS Quickshell desktop shell";
      wantedBy = [ "hyprland-session.target" "graphical-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/dms run";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    home.configFile."matugen/templates/hyprland-colors.conf".text = ''
      $accent = {{colors.primary.default.hex}}
      $background = {{colors.surface.default.hex}}
      $foreground = {{colors.on_surface.default.hex}}
    '';

    hey.hooks.reload."94-dms" = ''
      hey.do systemctl --user restart dms.service
    '';
  };
}
