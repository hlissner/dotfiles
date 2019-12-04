{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    direnv
    (import <nixpkgs-unstable> {}).lorri
  ];
}
