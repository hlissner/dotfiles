{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    rxvt_unicode
  ];
}
