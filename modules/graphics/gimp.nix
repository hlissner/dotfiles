{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gimp
    gimpPlugins.resynthesizer2
  ];
}
