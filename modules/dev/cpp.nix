{ config, lib, pkgs, ... }:

{
  imports = [ ./. ];

  environment.systemPackages = with pkgs; [
    clang
    gcc
    cmake
  ];
}
