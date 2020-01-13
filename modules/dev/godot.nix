# modules/dev/godot.nix --- https://godotengine.org/
#
# Gamedev is my hobby. C++ or Rust are my main drivers (and occasionally Lua),
# but to prototype (for 3D, mainly) I'll occasionally reach for godot.

{ pkgs, ... }:
{
  my.packages = with pkgs; [
    godot
  ];
}
