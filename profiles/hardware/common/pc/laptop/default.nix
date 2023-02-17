# profiles/hardware/common/pc/laptop/default.nix ---
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  imports = with self.modules.nixos-hardware; [
    common-pc-laptop
    ./battery.nix
  ];
}
