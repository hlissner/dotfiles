{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.quickshell;
    quickshellPackage = pkgs.symlinkJoin {
      name = "axiom-quickshell";
      paths = with pkgs.unstable; [
        quickshell
        kdePackages.qtbase
        kdePackages.qtdeclarative
        kdePackages.qtmultimedia
        kdePackages.qtpositioning
        kdePackages.qtsensors
        kdePackages.qtsvg
        kdePackages.qtwayland
        kdePackages.qtimageformats
        kdePackages.kirigami
        kdePackages.kdialog
        kdePackages.syntax-highlighting
        kdePackages.qt5compat
        adwaita-icon-theme
      ];
      meta.mainProgram = "quickshell";
    };
    searchHelper = pkgs.writeShellApplication {
      name = "axiom-search-helper";
      runtimeInputs = with pkgs; [ python3 wl-clipboard cliphist gtk3 xdg-utils libqalculate ];
      text = ''
        exec ${pkgs.python3}/bin/python3 ${hey.configDir}/quickshell/${cfg.configName}/search/axiom-search-helper.py "$@"
      '';
    };
    controlHelper = pkgs.writeShellApplication {
      name = "axiom-control-helper";
      runtimeInputs = with pkgs; [
        python3
        pamixer
        brightnessctl
        ddcutil
        playerctl
        wireplumber
        networkmanager
        bluez
        hyprland
        power-profiles-daemon
        wlogout
        procps
        lm_sensors
      ];
      text = ''
        exec ${pkgs.python3}/bin/python3 ${hey.configDir}/quickshell/${cfg.configName}/controls/axiom-control-helper.py "$@"
      '';
    };
in {
  options.modules.desktop.quickshell = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package quickshellPackage;
    configName = mkOpt str "axiom-shell";
    search.clipboard = {
      enable = mkBoolOpt true;
      backend = mkOpt (enum [ "cliphist" "axiom" ]) "cliphist";
      maxEntries = mkOpt int 500;
      maxEntryBytes = mkOpt int (64 * 1024);
    };
    phase4Services.enable = mkBoolOpt true;
    polkitAgent.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
      searchHelper
      controlHelper
      fuzzel
      gtk3
      xdg-utils
      wl-clipboard
      cliphist
      wlogout
      libnotify
      pamixer
      brightnessctl
      ddcutil
      playerctl
      wireplumber
      networkmanager
      bluez
      networkmanagerapplet
      blueman
      pavucontrol
    ] ++ optionals cfg.phase4Services.enable (with pkgs; [
      cava
      songrec
      libqalculate
      matugen
      swww
      imagemagick
      ffmpeg
      mpvpaper
      power-profiles-daemon
      procps
      lm_sensors
      kdePackages.kdialog
      kdePackages.polkit-kde-agent-1
    ]);

    fonts.packages = mkIf cfg.phase4Services.enable (with pkgs; [
      material-symbols
      googlesans-code
    ]);

    boot.kernelModules = mkIf cfg.phase4Services.enable [ "i2c-dev" ];
    hardware.i2c.enable = mkIf cfg.phase4Services.enable true;
    users.groups.i2c = mkIf cfg.phase4Services.enable {};
    user.extraGroups = mkIf cfg.phase4Services.enable [ "video" "input" "i2c" ];

    security.polkit.enable = mkIf cfg.phase4Services.enable true;
    services.power-profiles-daemon.enable = mkIf cfg.phase4Services.enable true;

    systemd.user.services.axiom-polkit-agent = mkIf (cfg.phase4Services.enable && cfg.polkitAgent.enable) {
      description = "Axiom graphical polkit agent";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    systemd.user.services.quickshell = {
      description = "Axiom Quickshell product shell";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/quickshell --config ${cfg.configName}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      environment = {
        AXIOM_CLIPBOARD_HISTORY = if cfg.search.clipboard.enable then "1" else "0";
        AXIOM_CLIPBOARD_BACKEND = cfg.search.clipboard.backend;
        AXIOM_CLIPBOARD_MAX_ENTRIES = toString cfg.search.clipboard.maxEntries;
        AXIOM_CLIPBOARD_MAX_ENTRY_BYTES = toString cfg.search.clipboard.maxEntryBytes;
      };
    };

    systemd.user.services.axiom-clipboard-history = mkIf cfg.search.clipboard.enable {
      description = "Axiom clipboard history watcher";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      environment = {
        AXIOM_CLIPBOARD_HISTORY = "1";
        AXIOM_CLIPBOARD_BACKEND = cfg.search.clipboard.backend;
        AXIOM_CLIPBOARD_MAX_ENTRIES = toString cfg.search.clipboard.maxEntries;
        AXIOM_CLIPBOARD_MAX_ENTRY_BYTES = toString cfg.search.clipboard.maxEntryBytes;
      };
      serviceConfig = {
        ExecStart = if cfg.search.clipboard.backend == "cliphist"
                    then "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
                    else "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${searchHelper}/bin/axiom-search-helper clipboard add";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    home.configFile = {
      "quickshell/${cfg.configName}" = {
        source = "${hey.configDir}/quickshell/${cfg.configName}";
        recursive = true;
      };
    };

    hey.hooks.reload."94-quickshell" = ''
      hey.do systemctl --user restart quickshell.service
    '';
  };
}
