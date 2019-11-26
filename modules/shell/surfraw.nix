{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    surfraw
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "surfraw".source = <config/surfraw>;
  };
}
