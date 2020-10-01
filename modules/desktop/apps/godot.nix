# modules/dev/godot.nix --- https://godotengine.org/
#
# Gamedev is my hobby. C++ or Rust are my main drivers (and occasionally Lua),
# but to prototype (for 3D, mainly) I'll occasionally reach for godot.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.godot;
in {
  options.modules.desktop.apps.godot = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      godot
    ];
  };
}
