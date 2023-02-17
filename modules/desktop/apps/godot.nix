# modules/dev/godot.nix --- https://godotengine.org/
#
# Gamedev is my hobby. C++ or Rust are my main drivers (and occasionally Lua),
# but to prototype (for 3D, mainly) I'll occasionally reach for godot.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.apps.godot;
in {
  options.modules.desktop.apps.godot = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs.unstable; [
      godot
    ];
  };
}
