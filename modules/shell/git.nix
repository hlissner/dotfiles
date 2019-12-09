{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gitAndTools.hub
    gitAndTools.diff-so-fancy
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "git" = { source = <config/git>; recursive = true; };
  };
}
