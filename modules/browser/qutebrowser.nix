# modules/browser/qutebrowser.nix --- https://github.com/qutebrowser/qutebrowser
#
# Qutebrowser is cute because it's not enough of a browser to be handsome.
# Still, we can all tell he'll grow up to be one hell of a lady-killer.

{ config, lib, pkgs, ... }:
{
  my.packages = [ pkgs.qutebrowser ];
  my.env.BROWSER = "qutebrowser";
  my.home.xdg = {
    configFile."qutebrowser" = {
      source = <config/qutebrowser>;
      recursive = true;
    };
    dataFile."qutebrowser/greasemonkey" = {
      source = <config/qutebrowser/greasemonkey>;
      recursive = true;
    };
  };
}
