{ config, lib, pkgs, ... }:

{
  imports = [
    ./emulators.nix
    ./factorio.nix
    ./steam.nix
  ];
}
