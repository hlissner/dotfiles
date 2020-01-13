# modules/recording.nix
#
# OBS to capture footage/stream, DaVinci Resolve for editing (on my Windows
# system -- it will run on linux, but it can't be automated on nix, what with
# their devs registration-gating their free download).

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    audacity   # for recording and remastering audio
    obs-studio # for streaming to twitch/recording for youtube
    handbrake  # for encoding footage
  ];
}
