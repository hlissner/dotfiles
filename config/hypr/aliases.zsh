#!/usr/bin/env zsh

alias -s pdf='$BROWSER'
alias -s {jpg,jpeg,gif,png,svg,webp}=swayimg

# swayimg opens at a fixed size and a hyprland window_rule floats/centers it, so
# resize it to fit the image.
function swayimg {
  local -a size
  local w h mw mh s
  if [[ -f $1 ]] && read -r w h < <(identify -ping -format '%w %h\n' "$1" 2>/dev/null); then
    if read -r mw mh < <(hyprctl -j monitors 2>/dev/null \
                          | jq -r '.[] | select(.focused) | "\(.width / .scale | floor) \(.height / .scale | floor)"'); then
      (( s = 0.96 * mw / w ))
      (( s > 0.96 * mh / h )) && (( s = 0.96 * mh / h ))
      (( s < 1 )) && { w=${$(( w * s ))%%.*}; h=${$(( h * s ))%%.*}; }
    fi
    size=( --size=$w,$h )
  fi
  command swayimg "${size[@]}" "$@"
}

alias dr='ripdrag'
alias y='wl-copy'
alias p='wl-paste'

(( $+commands[mpv] )) && alias -s {mp4,avi,mkv,mov}='mpv --loop'
(( $+commands[xdg-open] )) && alias open=xdg-open
(( $+commands[img2sixel] )) && alias six=img2sixel

alias reload='source /run/current-system/etc/set-environment'
