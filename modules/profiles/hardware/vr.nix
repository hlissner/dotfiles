# modules/profiles/hardware/vr.nix
#
# ALVR ports: udp/9943-9944
# SteamVR ports: udp/9944

{ hey, lib, options, config, ... }:

with lib;
with hey.lib;
mkIf (elem "vr" config.modules.profiles.hardware) {
  programs.alvr = {
    enable = true;
    openFirewall = true;
  };
}
