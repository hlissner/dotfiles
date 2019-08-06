{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    audacity
  ];
}
