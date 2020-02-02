# modules/dev/common-lisp.nix --- https://common-lisp.net/
#
# Mostly for my stumpwm config, and the occasional dip into lisp gamedev.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    sbcl
    lispPackages.quicklisp
  ];
}
