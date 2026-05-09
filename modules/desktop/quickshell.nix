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
    searchHelper = pkgs.writeShellApplication {
      name = "axiom-search-helper";
      runtimeInputs = with pkgs; [ python3 wl-clipboard gtk3 xdg-utils ];
      text = ''
        exec ${pkgs.python3}/bin/python3 ${hey.configDir}/quickshell/${cfg.configName}/search/axiom-search-helper.py "$@"
      '';
    };
    controlHelper = pkgs.writeShellApplication {
      name = "axiom-control-helper";
      runtimeInputs = with pkgs; [ python3 pamixer brightnessctl playerctl networkmanager bluez hyprland wlogout ];
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
      maxEntries = mkOpt int 500;
      maxEntryBytes = mkOpt int (64 * 1024);
    };
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
      wlogout
      libnotify
      pamixer
      brightnessctl
      playerctl
      networkmanager
      bluez
      networkmanagerapplet
      blueman
      pavucontrol
    ];

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
        AXIOM_CLIPBOARD_MAX_ENTRIES = toString cfg.search.clipboard.maxEntries;
        AXIOM_CLIPBOARD_MAX_ENTRY_BYTES = toString cfg.search.clipboard.maxEntryBytes;
      };
      serviceConfig = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${searchHelper}/bin/axiom-search-helper clipboard add";
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
