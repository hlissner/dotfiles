{ config, lib, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      qutebrowser
    ];
    variables.BROWSER = "qutebrowser";
  };

  home.xdg = {
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
