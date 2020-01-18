{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    vivaldi
    (pkgs.writeScriptBin "vivaldi-private" ''
      #!${stdenv.shell}
      ${vivaldi}/bin/vivaldi --incognito "$@"
    '')
    (makeDesktopItem {
      name = "vivaldi-private";
      desktopName = "Vivaldi (Incognito)";
      genericName = "Open an incognito Vivaldi window";
      icon = "vivaldi";
      exec = "${vivaldi}/bin/vivaldi --incognito";
      categories = "Network";
    })
  ];
  my.env.BROWSER = "vivaldi";
}
