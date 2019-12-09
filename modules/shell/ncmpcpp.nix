{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (ncmpcpp.override { visualizerSupport = true; })
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "ncmpcpp" = { source = <config/ncmpcpp>; recursive = true; };
  };
}
