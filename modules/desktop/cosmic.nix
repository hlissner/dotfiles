## modules/desktop/cosmic.nix
#
# Sets up a Gnome desktop environment inspired by PopOS's Cosmic DE.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.cosmic;
in {
  options.modules.desktop.cosmic = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # nixos conf
    environment.systemPackages = with pkgs; [
      pop-desktop-widget
      pop-control-center
      pop-launcher
      pop-shell-shortcuts
    ];

    user.packages = with pkgs; [
      gnome.nautilus
      gnome.gnome-shell-extensions
      gnomeExtensions.appindicator
      gnomeExtensions.pop-shell
      # gnomeExtensions.cosmic-dock
      gnomeExtensions.cosmic-workspaces
      gnomeExtensions.pop-cosmic
    ];

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      # displayManager.gdm.wayland = true;
      desktopManager.gnome.enable = true;
    };

    gnome.core-utilities.enable = true;

    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            # cosmic-dock needs dash-to-dock
            # "dash-to-dock@micxgx.gmail.com"
            #"cosmic-dock@system76.com"
            "native-window-placement@gnome-shell-extensions.gcampax.github.com"
            #"user-theme@gnome-shell-extensions.gcampax.github.com"
            #"workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "appindicatorsupport@rgcjonas.gmail.com"
            "pop-shell@system76.com"
            "cosmic-workspaces@system76.com"
            "pop-cosmic@system76.com"
            # For edu-screenshots
            "draw-on-your-screen2@zhrexl.github.com"
          ];
        };

        # disable incompatible shortcuts
        "org/gnome/mutter/wayland/keybindings" = {
          # restore the keyboard shortcuts: disable <super>escape
          restore-shortcuts = [];
        };
        "org/gnome/desktop/wm/keybindings" = {
          # hide window: disable <super>h
          minimize = [ "<super>comma" ];
          # switch to workspace left: disable <super>left
          switch-to-workspace-left = [];
          # switch to workspace right: disable <super>right
          switch-to-workspace-right = [];
          # maximize window: disable <super>up
          maximize = [];
          # restore window: disable <super>down
          unmaximize = [];
          # move to monitor up: disable <super><shift>up
          move-to-monitor-up = [];
          # move to monitor down: disable <super><shift>down
          move-to-monitor-down = [];
          # super + direction keys, move window left and right monitors, or up and down workspaces
          # move window one monitor to the left
          move-to-monitor-left = [];
          # move window one workspace down
          move-to-workspace-down = [];
          # move window one workspace up
          move-to-workspace-up = [];
          # move window one monitor to the right
          move-to-monitor-right = [];
          # super + ctrl + direction keys, change workspaces, move focus between monitors
          # move to workspace below
          switch-to-workspace-down = [ "<primary><super>down" "<primary><super>j" ];
          # move to workspace above
          switch-to-workspace-up = [ "<primary><super>up" "<primary><super>k" ];
          # toggle maximization state
          toggle-maximized = [ "<super>m" ];
          # close window
          close = [ "<super>q" "<alt>f4" ];
        };
        "org/gnome/shell/keybindings" = {
          open-application-menu = [];
          # toggle message tray: disable <super>m
          toggle-message-tray = [ "<super>v" ];
          # show the activities overview: disable <super>s
          toggle-overview = [];
        };
        "org/gnome/mutter/keybindings" = {
          # disable tiling to left / right of screen
          toggle-tiled-left = [];
          toggle-tiled-right = [];
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          # lock screen
          screensaver = [ "<super>escape" ];
          # home folder
          home = [ "<super>f" ];
          # launch email client
          email = [ "<super>e" ];
          # launch web browser
          www = [ "<super>b" ];
          # launch terminal
          terminal = [ "<super>t" ];
          # rotate video lock
          rotate-video-lock-static = [];
        };
        "org/gnome/mutter" = {
          workspaces-only-on-primary = false;
        };
      };
    };
  };
}
