{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gimp
    gimpPlugins.resynthesizer2
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "GIMP/2.10" = { source = <config/gimp>; recursive = true; };
  };
}
