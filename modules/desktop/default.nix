{ config, lib, pkgs, ... }:

{
  imports = [
    ./bspwm.nix
    # ./stumpwm.nix

    ./apps
    ./term
    ./browsers
    ./gaming
  ];
}
