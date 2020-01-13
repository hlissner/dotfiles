# modules/dev/love2d.nix --- https://love2d.org/
#
# Love is my favorite little game engine. I use it often for rapid prototyping
# when godot is overkill and have the luxury of avoiding JS. I write my Love
# games in moonscript to get around the idiosynchrosies of lua.

{ pkgs, ... }:
{
  my.packages = with pkgs; [
    love
    lua
    luaPackages.moonscript
    luarocks
  ];
}
