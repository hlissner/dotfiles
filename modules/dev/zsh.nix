{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    shellcheck
    (callPackage (import <my/packages/zunit.nix> {}))
  ];
}
