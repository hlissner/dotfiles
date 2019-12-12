{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    xfce.thunar
    xfce.tumbler # for thumbnails
  ];
}
