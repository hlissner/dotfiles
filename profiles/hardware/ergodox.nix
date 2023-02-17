{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  user.packages = [ pkgs.unstable.wally-cli ];

  hardware.keyboard.zsa.enable = true;

  user.extraGroups = [ "plugdev" ];

  services.xserver.xkbOptions = "compose:ralt";
}
