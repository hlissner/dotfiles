{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "ergodox" config.modules.profiles.hardware) {
  user.packages = [ pkgs.wally-cli ];

  hardware.keyboard.zsa.enable = true;

  user.extraGroups = [ "plugdev" ];

  services.xserver.xkbOptions = "compose:ralt";
}
