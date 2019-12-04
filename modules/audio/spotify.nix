{ config, lib, pkgs, ... }:

let unstable = import <nixpkgs-unstable> {};
in
{
  environment.systemPackages = with pkgs; [
    # services.spotifyd doesn't work so...
    spotifyd
    (writeScriptBin "spt" ''
      #!${stdenv.shell}
      if ! pgrep -x spotifyd >/dev/null; then
        spotifyd --backend pulseaudio \
                 --cache_path ~/.cache/spotifyd \
                 --username accounts@v0.io \
                 --password $(pass www/spotify.com)
      fi
      ${unstable.spotify-tui}/bin/spt
    '')

    # spotify-tui is fine for selecting and playing music, but incomplete. We
    # occasionally still need the official client.
    spotify
  ];
}
