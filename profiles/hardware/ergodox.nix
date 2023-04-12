{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  user.packages = [ pkgs.wally-cli ];

  hardware.keyboard.zsa.enable = true;

  user.extraGroups = [ "plugdev" ];

  services.xserver.xkbOptions = "compose:ralt";
}
