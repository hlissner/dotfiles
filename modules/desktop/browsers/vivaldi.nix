# modules/browser/vivaldi.nix --- ...

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.browsers.vivaldi = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.vivaldi.enable {
    my.packages = with pkgs; [
      vivaldi
      vivaldi-widevine
      (makeDesktopItem {
        name = "vivaldi-private";
        desktopName = "Vivaldi (Incognito)";
        genericName = "Open an incognito Vivaldi window";
        icon = "vivaldi";
        exec = "${vivaldi}/bin/vivaldi --incognito";
        categories = "Network";
      })
    ];
  };
}
