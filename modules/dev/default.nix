{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnumake
  ];
}
