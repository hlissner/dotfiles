{ config, lib, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      libsForQt5.qtstyleplugins
      # qt5.qtbase  # make Qt 5 apps inherit GTK2 theme
    ];

    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "gtk2";
      GTK_DATA_PREFIX = [ "${config.system.path}" ];
      GTK2_RC_FILES = "$HOME/.config/gtk-2.0/gtkrc";
    };
  };
  services.xserver.displayManager.sessionCommands = ''
    source "$XDG_CONFIG_HOME"/xsession/*.sh
    xrdb -merge "$XDG_CONFIG_HOME"/xtheme/*
  '';
}
