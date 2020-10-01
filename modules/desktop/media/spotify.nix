# I use spotify for my music needs. Gone are the days where I'd manage 200gb+ of
# local music; most of which I haven't heard or don't even like.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.spotify;
in {
  options.modules.desktop.media.spotify = {
    enable = mkBoolOpt false;
    tui.enable = mkBoolOpt false;  # TODO
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # spotify-tui is fine for selecting and playing music, but incomplete. We
      # still occasionally need the official client for more sophisticated
      # search and the "made for you" playlists.
      spotify

      # # services.spotifyd doesn't work so we'll have to roll our own spotifyd +
      # # spotify-tui solution. The dbus interface doesn't work, though, so we
      # # have to wait for spotify-tui to implement CLI command for controlling
      # # spotify playback. See
      # # https://github.com/Rigellute/spotify-tui/issues/147 or for spotifyd to
      # # get fixed.
      # master.spotifyd
      # (writeScriptBin "spt" ''
      #   #!${stdenv.shell}
      #   if ! systemctl --user is-active spotifyd >/dev/null; then
      #     systemctl --user start spotifyd
      #   fi
      #   echo $TMUX >/tmp/spt.tmux
      #   exec ${master.spotify-tui}/bin/spt
      # '')

      # # Since dbus doesn't work with Nix's spotifyd/spotify-tui, and I always
      # # use tmux for my terminal, may as well exploit tmux to control spotify.
      # playerctl
      # (writeScriptBin "spt-send" ''
      #    #!${stdenv.shell}
      #    dbus_cmd='playerctl -p spotify'
      #    tmux_cmd="tmux send-keys -t $(cat /tmp/spt.tmux | cut -d, -f3)"
      #    case "$1" in
      #      toggle) $dbus_cmd play-pause 2>/dev/null || $tmux_cmd " " ;;
      #      next) $dbus_cmd next 2>/dev/null       || $tmux_cmd n ;;
      #      prev) $dbus_cmd previous 2>/dev/null   || $tmux_cmd p ;;
      #    esac
      #  '')

      # (writeScriptBin "spt-send-notify" ''
      #    #!${stdenv.shell}
      #    client_id=$(pass www/spotify.com | grep -E '^client_id:' | awk '{print $2}')
      #    client_secretd=$(pass www/spotify.com | grep -E '^client_secret:' | awk '{print $2}')
      #    jq="${pkgs.jq}/bin/jq"

      #    token=$(curl -s -X 'POST' -u $client_id:$client_secretd -d grant_type=client_credentials https://accounts.spotify.com/api/token | $jq '.access_token' | cut -d\" -f2)
      #    result=$?
      #    if [[ $result != 0 ]]; then
      #      notify-send "spt-send failure" "Could not acquire token"
      #      exit 1
      #    fi
      #    case "$PLAYER_EVENT" in
      #        start)
      #            curl -s -X 'GET' https://api.spotify.com/v1/tracks/$TRACK_ID -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization:\"Bearer $token\"" | $jq '.name, .artists[].name, .album.name, .album.release_date, .track_number, .album.total_tracks' | xargs printf "\"Playing '%s' from '%s' (album: '%s' in %s (%s/%s))\"" | xargs notify-send --urgency=low --expire-time=3000 --icon=/usr/share/icons/gnome/32x32/actions/player_play.png --app-name=spotifyd spotifyd
      #            ;;
      #        stop)
      #            curl -s -X 'GET' https://api.spotify.com/v1/tracks/$TRACK_ID -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization:\"Bearer $token\"" | $jq '.name, .artists[].name, .album.name, .album.release_date, .track_number, .album.total_tracks' | xargs printf "Stoping music (Last song: '%s' from '%s' (album: '%s' in %s (%s/%s)))\"" | xargs notify-send --urgency=low --expire-time=3000 --icon=/usr/share/icons/gnome/32x32/actions/player_stop.png --app-name=spotifyd spotifyd
      #            ;;
      #        change)
      #            curl -s -X 'GET' https://api.spotify.com/v1/tracks/$TRACK_ID -H 'Accept: application/json' -H 'Content-Type: application/json' -H "Authorization:\"Bearer $token\"" | $jq '.name, .artists[].name, .album.name, .album.release_date, .track_number, .album.total_tracks' | xargs printf "\"Music changed to '%s' from '%s' (album: '%s' in %s (%s/%s))\"" | xargs notify-send --urgency=low --expire-time=3000 --icon=/usr/share/icons/gnome/32x32/actions/player_fwd.png --app-name=spotifyd spotifyd
      #            ;;
      #        *)  2>&1 echo "Unkown event."
      #            exit 2
      #            ;;
      #    esac
      # '')
    ];

  #   systemd.user.services.spotifyd.serviceConfig =
  #     let spotifydConf = pkgs.writeText "spotifyd.conf" ''
  #         [global]
  #         username = g2qwjcs6334oacg1zg9wrihnn
  #         password_cmd = ${pkgs.pass}/bin/pass www/spotify.com | head -n1
  #         backend = pulseaudio
  #         on_song_change_hook = spt-send-notify
  #         cache_path = ${config.my.home}/.cache/spotifyd
  #       '';
  #     in {
  #       ExecStart = ''
  #         ${pkgs.master.spotifyd}/bin/spotifyd --no-daemon \
  #                                                --cache-path /tmp/spotifyd \
  #                                                --config-path ${spotifydConf}
  #       '';
  #       Restart = "always";
  #       RestartSec = 6;
  #     };
  };
}
