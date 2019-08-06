{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
  ];

  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
}
