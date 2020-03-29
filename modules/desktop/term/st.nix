{ config, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.term.st = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.term.st.enable {
    # xst-256color isn't supported over ssh, so revert to a known one
    my.zsh.rc = ''[ "$TERM" = xst-256color ] && export TERM=xterm-256color'';

    my.packages = with pkgs; [
      xst  # st + nice-to-have extensions
      (makeDesktopItem {
        name = "xst";
        desktopName = "Suckless Terminal";
        genericName = "Default terminal";
        icon = "utilities-terminal";
        exec = "${xst}/bin/xst";
        categories = "Development;System;Utility";
      })
    ];
  };
}
