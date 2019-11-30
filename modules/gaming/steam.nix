{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    steam-run-native  # for GOG or humblebundle games
  ];

  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
}
