# modules/dev/godot.nix --- https://godotengine.org/
#
# Gamedev is my hobby. C++ or Rust are my main drivers (and occasionally Lua),
# but to prototype (for 3D, mainly) I'll occasionally reach for godot.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.godot = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.godot.enable {
    my.packages = with pkgs; [
      godot
    ];
  };
}
