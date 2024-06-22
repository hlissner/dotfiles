#!/usr/bin/env zsh
# Propagate envvars to systemd or tmux.
#
# SYNOPSIS:
#   export-env [systemd|tmux] [ENVVARS...]
#
# DESCRIPTION:
#   Propagate ENVVARS to an external tool (like systemd or tmux). If ENNVARS are
#   omitted, a set of sensible envvars are exported. If given -a or --all, the
#   whole environment is exported (dangerous!).
#
# SUBCOMMANDS:
#   tmux         import to tmux server
#   system       import to systemd and dbus user session
#
# OPTIONS:
#   -a, --all
#     Export the whole environment, rather than just a select few.

zparseopts -E -D -F -- {a,-all}=all || exit 1

local -a _envs
if (( $# > 1 )); then
  _envs=( ${@:2} )
elif [[ $all ]]; then
  _envs=( $(env | cut -d= -f 1 | grep -vE '^_') )
else
  _envs=(
    # display
    WAYLAND_DISPLAY
    DISPLAY
    # xdg
    USERNAME
    XDG_BACKEND
    XDG_CURRENT_DESKTOP
    XDG_SESSION_TYPE
    XDG_SESSION_ID
    XDG_SESSION_CLASS
    XDG_SESSION_DESKTOP
    XDG_SEAT
    XDG_VTNR
    # bspwm
    BSPWM_SOCKET
    # hyprland
    HYPRLAND_CMD
    HYPRLAND_INSTANCE_SIGNATURE
    # sway
    SWAYSOCK
    # misc
    XCURSOR_THEME
    XCURSOR_SIZE
    GTK_THEME
    # toolkit
    _JAVA_AWT_WM_NONREPARENTING
    QT_QPA_PLATFORM
    QT_WAYLAND_DISABLE_WINDOWDECORATION
    GRIM_DEFAULT_DIR
    # ssh
    SSH_AUTH_SOCK
  )
fi

for v in "${_envs[@]}"; do
  if [[ -n ${(P)v} ]]; then
    hey.log "$v = ${(P)v}"
  fi
done
main() {
  case $1 in
    systemd)
      systemctl --user import-environment "${_envs[@]}"
      echo "Exported to systemd: ${_envs[@]}"
      # Not necessary for dbus-broker, which simply uses the systemd environment
      if (( $+commands[dbus-update-activation-environment] )); then
        dbus-update-activation-environment --systemd "${_envs[@]}"
        echo "Exported to dbus"
      fi
      ;;
    tmux)
      for v in "${_envs[@]}"; do
        if [[ -n ${(P)v} ]]; then
          tmux setenv -g "$v" "${(P)v}"
        fi
      done
      echo "Exported to tmux"
      ;;
    *)
      hey.error -D "$ZSH_ARGZERO" -c "$1"
      exit 1
      ;;
  esac
}

main $@
