{ config, lib, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (writeScriptBin "rofi" ''
        #!${stdenv.shell}
        exec ${rofi}/bin/rofi -terminal xst -theme "$XDG_CONFIG_HOME/rofi/theme" -m -1 $@
        '')
      rofi
    ];

    # shellAliases = {};
  };

  home-manager.users.hlissner.xdg.configFile = {
    # link recursively so other modules can link files in its folder
    "rofi" = { source = <config/rofi>; recursive = true; };
  };
}
