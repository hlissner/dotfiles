{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.aseprite-unfree
  ];
}
