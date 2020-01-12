# I don't often use Unity, but I've worked with others who do. I'll commonly
# reach for it for group projects.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    unity3d
  ];
}
