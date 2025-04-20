# modules/dev/godot.nix --- https://godotengine.org/
#
# Gamedev is my hobby. C++ or Rust are my main drivers (and occasionally Lua),
# but to prototype (for 3D, mainly) I often reach for godot (or Love2D).

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.godot;
in {
  options.modules.desktop.apps.godot = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      godot_4
      godot_4-export-templates
      gdtoolkit_4
    ];
  };
}
