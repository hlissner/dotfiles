{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    sbcl
  ];
}
