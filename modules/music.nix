# I use spotify for my music needs. Gone are the days where I'd manage 200gb+ of
# local music; most of which I haven't heard or don't even like.

{ config, lib, pkgs, ... }:
{
  # services.spotifyd doesn't work so we'll have to roll our own spotifyd +
  # spotify-tui solution. The dbus interface doesn't work, though, so we have to
  # wait for spotify-tui to implement CLI command for controlling spotify
  # playback. See https://github.com/Rigellute/spotify-tui/issues/147 or for
  # spotifyd to get fixed.
  my.packages = with pkgs; [
    unstable.spotifyd
    (writeScriptBin "spt" ''
      #!${stdenv.shell}
      if ! systemctl --user is-active spotifyd >/dev/null; then
        systemctl --user start spotifyd
      fi
      ${unstable.spotify-tui}/bin/spt
    '')

    # spotify-tui is fine for selecting and playing music, but incomplete. We
    # occasionally still need the official client for more sophisticated search
    # and the "made for you" playlists.
    spotify
  ];

  systemd.user.services.spotifyd.serviceConfig =
    let spotifydConf = pkgs.writeText "spotifyd.conf" ''
        [global]
        username = g2qwjcs6334oacg1zg9wrihnn
        password_cmd = ${pkgs.pass}/bin/pass www/spotify.com | head -n1
        backend = pulseaudio
      '';
    in {
      ExecStart = "${pkgs.unstable.spotifyd}/bin/spotifyd --no-daemon --cache-path /tmp/spotifyd --config-path ${spotifydConf}";
      Restart = "always";
      RestartSec = 6;
    };
}
