# config/supersonic/subsonic.zsh
#
# Talk to the Subsonic server Supersonic is logged into, as Supersonic, for the
# things its IPC can't do. Sourced by the scripts in bin/.

hey.requires supersonic secret-tool curl jq

# The first [[Servers]] entry: Supersonic doesn't write down which one it's
# logged into, and I only have the one.
subsonic.server() {
  [[ -n ${SUBSONIC_SERVER-} ]] && return
  local config=${XDG_CONFIG_HOME:-$HOME/.config}/supersonic/config.toml
  .conf() { sed -n "s/^$1 = '\(.*\)'$/\1/p" $config | head -1 }
  SUBSONIC_HOST=$(.conf Hostname)
  SUBSONIC_USER=$(.conf Username)
  SUBSONIC_SERVER=$(.conf ID)
  [[ -n $SUBSONIC_HOST && -n $SUBSONIC_USER && -n $SUBSONIC_SERVER ]] \
    || hey.abort "No server in $config"
}

# subsonic.playing KIND
#
# Sets id/name/sub/cover to the song Supersonic is playing (KIND=song), its
# album, or its album artist. Aborts if nothing's playing.
subsonic.playing() {
  subsonic.server
  # sub comes last: it may be empty, and read folds consecutive tabs.
  local cover_id album_id
  IFS=$'\t' read -r cover_id album_id id name sub < <(
    supersonic -current-track 2>/dev/null | jq -r --arg k $1 '
      select(.ID) | [.CoverArtID, .AlbumID]
      + if $k == "song" then [.ID, .Name, ((.Artists | join(", ")) + " · " + .Album)]
        elif $k == "album" then [.AlbumID, .Album, (.Artists | join(", "))]
        else ["", "", ""] end
      | @tsv' || :
  ) || :
  [[ -n $album_id ]] || hey.abort "Supersonic isn't playing anything"
  if [[ $1 == artist ]]; then
    # Supersonic only knows the track's artists, which aren't necessarily the
    # album's. The album knows.
    IFS=$'\t' read -r id name < <(
      subsonic.api getAlbum id=$album_id | jq -r '.album | [.artistId, .artist] | @tsv' || :
    ) || :
    [[ -n $id ]] || hey.abort "The server doesn't know whose album that is"
  fi
  cover=${XDG_CACHE_HOME:-$HOME/.cache}/supersonic/$SUBSONIC_SERVER/covers/$cover_id.jpg
  [[ -f $cover ]] || cover=
}

# subsonic.api ENDPOINT [KEY=VALUE...]
#
# Prints the response's body (minus the subsonic-response wrapper). Subsonic
# answers 200 to everything, so failure is read out of the body.
subsonic.api() {
  local endpoint=$1 res kv; shift
  if [[ -z ${SUBSONIC_TOKEN-} ]]; then
    subsonic.server
    # go-keyring files it under service=APPNAME username=SERVERID.
    local pass
    pass=$(secret-tool lookup service supersonic username $SUBSONIC_SERVER) && [[ -n $pass ]] \
      || hey.abort "Supersonic's password for $SUBSONIC_HOST isn't in the keyring"
    # Token auth: the password never goes on the wire, and printf is a builtin,
    # so never into an argv either.
    SUBSONIC_SALT=$(head -c 8 /dev/urandom | xxd -p)
    SUBSONIC_TOKEN=$(printf %s "$pass$SUBSONIC_SALT" | md5sum | cut -d' ' -f1)
  fi
  local -a query=( --data-urlencode "u=$SUBSONIC_USER"
                   --data-urlencode "t=$SUBSONIC_TOKEN"
                   --data-urlencode "s=$SUBSONIC_SALT"
                   -d v=1.16.1 -d c=hey -d f=json )
  for kv in "$@"; do query+=( --data-urlencode "$kv" ); done
  res=$(curl -sfG "$SUBSONIC_HOST/rest/$endpoint" $query) \
    || hey.abort "Couldn't reach $SUBSONIC_HOST"
  [[ $(jq -r '."subsonic-response".status' <<<$res) == ok ]] \
    || hey.abort "$SUBSONIC_HOST: $(jq -r '."subsonic-response".error.message' <<<$res)"
  jq '."subsonic-response"' <<<$res
}
