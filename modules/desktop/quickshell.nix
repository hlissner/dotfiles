{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.quickshell;
    quickshellPackage = pkgs.symlinkJoin {
      name = "axiom-quickshell";
      paths = with pkgs.unstable; [
        quickshell
        kdePackages.qtimageformats
        kdePackages.kirigami
        adwaita-icon-theme
      ];
      meta.mainProgram = "quickshell";
    };
in {
  options.modules.desktop.quickshell = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package quickshellPackage;
    configName = mkOpt str "axiom-shell";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
      fuzzel
      wlogout
      libnotify
      playerctl
      networkmanagerapplet
      blueman
      pavucontrol
    ];

    systemd.user.services.quickshell = {
      description = "Axiom Quickshell product shell";
      wantedBy = [ "hyprland-session.target" "graphical-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/quickshell --config ${cfg.configName}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    home.configFile = {
      "quickshell/${cfg.configName}" = {
        source = "${hey.configDir}/quickshell/${cfg.configName}";
        recursive = true;
      };
      "axiom-desktop/guide.md".source = "${hey.configDir}/axiom-desktop/guide.md";
    };

    hey.hooks.reload."94-quickshell" = ''
      hey.do systemctl --user restart quickshell.service
    '';
  };
}
