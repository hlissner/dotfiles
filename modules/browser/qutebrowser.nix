{ config, lib, pkgs, ... }:
{
  my.packages = [ pkgs.qutebrowser ];
  my.env.BROWSER = "qutebrowser";
  my.home.xdg = {
    configFile."qutebrowser" = {
      source = <my/config/qutebrowser>;
      recursive = true;
    };
    dataFile."qutebrowser/greasemonkey" = {
      source = <my/config/qutebrowser/greasemonkey>;
      recursive = true;
    };
  };
}
