{ config, lib, pkgs, ... }:

{
  imports = [ ./. ];

  my.packages = with pkgs; [
    clang
    gcc
    cmake
    llvmPackages.libcxx
  ];
}
