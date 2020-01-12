# I use OBS to capture footage/stream and DaVinci Resolve for editing (on my
# Windows system -- it will run on windows, but there is no way to automate its
# installation, what with their devs regsitration-gating their free download).
#
# I also use ffmpeg for small casts/gifs, but this module is for the heavy duty
# stuff.
#
# This module is best paired with ./audio-editing.nix

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    audacity   # for recording and remastering audio
    obs-studio # for streaming to twitch/recording for youtube
    handbrake  # for encoding footage
  ];
}
