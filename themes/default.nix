{ config, lib, pkgs, ... }:

{
  environment.variables = {
    GTK_DATA_PREFIX = [ "${config.system.path}" ];
    QT_QPA_PLATFORMTHEME = "gtk2";
  };

  qt5 = {
    style = "gtk2";
    platformTheme = "gtk2";
  };

  services.xserver.displayManager.sessionCommands = ''
    export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
    source "$XDG_CONFIG_HOME"/xsession/*.sh
    xrdb -merge "$XDG_CONFIG_HOME"/xtheme/*
  '';
}
