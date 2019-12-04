{ config, lib, pkgs, ... }:

{
  environment.variables = {
    GTK_DATA_PREFIX = [ "${config.system.path}" ];
    GTK2_RC_FILES = "$HOME/.config/gtk-2.0/gtkrc";
    QT_QPA_PLATFORMTHEME = "gtk2";
  };

  qt5 = {
    style = "gtk2";
    platformTheme = "gtk2";
  };

  services.xserver.displayManager.sessionCommands = ''
    source "$XDG_CONFIG_HOME"/xsession/*.sh
    xrdb -merge "$XDG_CONFIG_HOME"/xtheme/*
  '';
}
