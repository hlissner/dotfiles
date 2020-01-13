# I gamedev as a hobby. For making games, I mainly use C++ or Rust (and
# occasionally Lua). However, when I need to prototype an idea, I reach for
# godot (or JS, if I want it to be playable for others).

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    godot
  ];
}
