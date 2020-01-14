{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    vivaldi
  ];
  my.env.BROWSER = "vivaldi";
}
