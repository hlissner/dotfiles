# modules/desktop/apps/recording.nix
#
# OBS to capture footage/stream, DaVinci Resolve for editing (on my Windows
# system -- it will run on linux, but it can't be automated on nix, what with
# their devs registration-gating their free download).

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.apps.recording =
    let mkBoolDefault = bool: mkOption {
          type = types.bool;
          default = bool;
        };
    in {
      enable = mkBoolDefault false;
      audio.enable = mkBoolDefault false;
      video.enable = mkBoolDefault false;
    };

  config = let rc = config.modules.desktop.apps.recording; in {
    my.packages = with pkgs;
      # for recording and remastering audio
      (if rc.enable || rc.audio.enable then [ audacity ] else []) ++
      # for longer term streaming/recording the screen
      (if rc.enable || rc.video.enable then [ obs-studio handbrake ] else []);
  };
}
