{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mpc_cli
  ];

  my.env.MPD_HOME = "$XDG_CONFIG_HOME/mpd";

  services.mpd = {
    enable = true;
    musicDirectory = "/home/hlissner/music";
    startWhenNeeded = true;
    extraConfig = ''
      input {
          plugin "curl"
      }
      audio_output {
          type        "pulse"
          name        "pulse audio"
      }
      audio_output {
          type        "fifo"
          name        "mpd_fifo"
          path        "/tmp/mpd.fifo"
          format      "44100:16:2"
      }
    '';
  };
}
