# I don't often use unity except for team projects. On my own, I prefer rolling
# my own (or godot).

{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unity3d
  ];
}
