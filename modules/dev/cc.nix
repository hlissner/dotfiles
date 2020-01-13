{ config, lib, pkgs, ... }:

{
  imports = [ ./. ];

  my.packages = with pkgs; [
    clang
    gcc
    bear
    gdb
    cmake
    llvmPackages.libcxx
    ccls
  ];
}
