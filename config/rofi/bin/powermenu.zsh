#!/usr/bin/env zsh
# Control the system's power state.
#
# SYNOPSIS:
#   TODO

.rofi() {
  rofi -dmenu -i -theme powermenu.rasi $@
  if (( $? > 0 )); then
    hey.error "Nothing selected. Aborting..."
    exit 1
  fi
}

rofi.powermenu.dpms() {
  sleep 0.2
  if (( $+commands[hyprctl] )); then
    hey.do hyprctl dispatch dpms off
  elif (( $+commands[xset] )); then
    hey.do xset dpms force off
  else
    notify-send "Unexpected error" "No known method to sleep monitors" -i system-error
    exit 1
  fi
}

rofi.powermenu.lock()     { hey.do loginctl lock-session; }

rofi.powermenu.suspend()  { hey.do systemctl suspend; }

rofi.powermenu.reboot()   { hey.do systemctl reboot; }

rofi.powermenu.poweroff() { hey.do systemctl poweroff; }

rofi.powermenu.reboot-into() {
  local entries=$(bootctl list --json=short)
  IFS=$'\n' local -a lines=( $(jq -r '.[] | (.id+";"+.title+";"+.version)' <<<$entries) )
  local i=$(for line in ${lines[@]}; do
              IFS=\; read id title version <<<"$line"
              title=${title:-$id}
              [[ $version ]] && title="$title ($version)"
              echo -e "$title\0icon\x1ffolder\x1fmeta\x1f$id"
            done | .rofi -format d)
  hey.log "Rebooting into: ${lines[$i]}"
  hey.do systemctl reboot --boot-loader-entry \
    $(jq -r --arg id "${lines[$i]/;*}" '.[] | select(.id == $id) | .id' <<<$entries)
}

local cmds=(
  "Turn off displays;system-config-display;rofi.powermenu.dpms"
  "Lock session;system-lock-screen;rofi.powermenu.lock"
  "Suspend;system-suspend;rofi.powermenu.suspend"
  "Reboot;system-reboot;rofi.powermenu.reboot"
  "Reboot into...;system-log-out;rofi.powermenu.reboot-into"
  "Power off;system-shutdown;rofi.powermenu.poweroff"
)

local i=$(for item in ${(k)cmds}; do
            IFS=\; read title icon cmd <<<"$item"
            echo -e "$title\0icon\x1f$icon"
          done | .rofi -format d)
${cmds[$i]/*;/}
