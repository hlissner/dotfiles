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

# bootctl entries are noisy and pack too much into rofi I can't see the
# important things, so massage the list a bit.
.bootentries() {
  local icons=${XDG_CONFIG_HOME:-$HOME/.config}/rofi/icons
  local booted=$(readlink -f /run/booted-system)
  local id title version options default icon gen desc date kernel nixos
  local -a tags
  while IFS=$'\t' read -r id title version options default; do
    title=${title:-$id}
    title=${${${title//&/&amp;}//</&lt;}//>/&gt;}  # -markup-rows is on
    icon=$icons/linux.svg
    [[ $title == *[Ww]indows* ]]  && icon=$icons/windows.svg
    [[ $title == *[Mm]emtest* ]]  && icon=gnome-dev-memory  # a RAM stick
    [[ $title == *[Ff]irmware* ]] && icon=preferences-system-symbolic
    if [[ $version =~ '^Generation ([0-9]+) (.*), built on ([0-9-]+)$' ]]; then
      icon=$icons/nixos.svg
      gen=$match[1] desc=$match[2] date=$match[3]
      # "NixOS Zokor 26.11.20260917.e554fab (Linux 7.2.6-xanmod1)"
      [[ $desc =~ '\(Linux ([^)]+)\)' ]] && kernel="Linux $match[1]" || kernel=
      desc=${desc%% \(Linux*}
      [[ $desc =~ '[0-9]+(\.[0-9]+)+' ]] && nixos=$MATCH || nixos=$desc
      tags=()
      [[ $options == *init=$booted/init* ]] && tags+=(running)
      [[ $default == true ]] && tags+=(default)
      title=$(printf '<b>%-5s</b> %-15s <span alpha="55%%">%-20s %s</span>%s' \
                     "$gen" "$nixos" "$kernel" "$date" \
                     "${tags:+ <i>${(j:, :)tags}</i>}")
    fi
    echo -e "$title\0icon\x1f$icon\x1fmeta\x1f$id"
  done
}

rofi.powermenu.reboot-into() {
  # type1  = an entry file on the ESP
  # auto   = sd-boot's own (Windows, firmware setup)
  # loader = dead boot loader entry (leftover from rebuilds)
  local -a lines=( ${(f)"$(bootctl list --json=short |
                           jq -r '.[] | select(.type != "loader")
                                      | [.id, .title, .version, (.options // ""), .isDefault] | @tsv')"} )
  local i=$(printf '%s\n' $lines | .bootentries | .rofi -markup-rows -format d)
  # .rofi's exit only kills its own subshell, and falling through from here
  # reboots the machine. Escape should mean escape.
  [[ $i ]] || exit 1
  local id title version
  IFS=$'\t' read -r id title version _ <<<$lines[$i]
  hey.log "Rebooting into: ${version:-$title}"
  hey hook on-rebooting
  hey.do systemctl reboot --boot-loader-entry $id
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
