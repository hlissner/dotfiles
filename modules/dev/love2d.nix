{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    love
    lua
    luaPackages.moonscript
    luarocks
  ];
}
