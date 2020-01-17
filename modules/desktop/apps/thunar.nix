{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    xfce.thunar
    xfce.tumbler # for thumbnails
  ];
}
