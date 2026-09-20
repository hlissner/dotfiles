#!/usr/bin/env zsh
# Control the current session's state.
#
# SYNOPSIS:
#   hey @rofi powermenu [dpms|lock|suspend|logout|reboot|poweroff|reboot-into]
#
# ARGUMENTS:
#   1 ACTION
#     dpms
#     lock
#     suspend
#     logout
#     reboot
#     poweroff
#     reboot-into

.rofi() {
  rofi -dmenu -i -theme powermenu.rasi $@
  if (( $? > 0 )); then
    hey.error "Nothing selected. Aborting..."
    exit 1
  fi
}

rofi.powermenu.dpms() {
  sleep 0.2
  hey.do hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "disable" }))'
}

rofi.powermenu.lock()     {
  hey hook on-session-locked
  hey.do loginctl lock-session;
}

rofi.powermenu.suspend()  { hey.do systemctl suspend; }

rofi.powermenu.logout()   {
  if uwsm check is-active &>/dev/null; then
    hey.do uwsm stop;
  else
    hey.do loginctl terminate-session ${XDG_SESSION_ID:-self};
  fi
}

rofi.powermenu.reboot()   {
  hey hook on-rebooting
  hey.do systemctl reboot;
}

rofi.powermenu.poweroff() {
  hey hook on-shutting-down
  hey.do systemctl poweroff;
}

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
  hey hook on-rebooting
  hey.do systemctl reboot --boot-loader-entry \
    $(jq -r --arg id "${lines[$i]/;*}" '.[] | select(.id == $id) | .id' <<<$entries)
}

local cmds=(
  "Turn off displays;display-symbolic;rofi.powermenu.dpms"
  "Lock session;system-lock-screen-symbolic;rofi.powermenu.lock"
  "Log out;system-log-out-symbolic;rofi.powermenu.logout"
  "Suspend;system-suspend-symbolic;rofi.powermenu.suspend"
  "Reboot;system-reboot-symbolic;rofi.powermenu.reboot"
  "Reboot into...;go-jump-symbolic;rofi.powermenu.reboot-into"
  "Power off;system-shutdown-symbolic;rofi.powermenu.poweroff"
)

if [[ -n "$1" ]]; then
  "rofi.powermenu.$1"
else
  local i=$(for item in ${(k)cmds}; do
              IFS=\; read title icon cmd <<<"$item"
              echo -e "$title\0icon\x1f$icon"
            done | .rofi -format d)
  ${cmds[$i]/*;/}
fi
