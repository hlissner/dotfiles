#!/usr/bin/env zsh
# Toggle drawing on the screen.
#
# SYNOPSIS:
#   screendraw
#
# DESCRIPTION:
#   Temporarily launches gromit-mpx, enabling you to draw on the screen. Also
#   includes OSD indicators.
#
# DEPENDENCIES:
#   gromit-mpx

#
#   There
#           can only
#
#
#                        be
#
#                              one.
#
if pidof gromit-mpx >/dev/null; then
  pkill gromit-mpx
  exit
fi

# gromit-mpx lacks CLI options to configure it, but I insist on using it as a
# one-shot on-demand tool, so...
local inifile=$XDG_CONFIG_HOME/gromit-mpx.ini
cat >$inifile <<-EOF
  [General]
  ShowIntroOnStartup=false
EOF

local cfgfile=$XDG_CONFIG_HOME/gromit-mpx.cfg
cat >$cfgfile <<EOF
  "red Pen" = PEN (size=5 color="red");
  "blue Pen" = "red Pen" (color="blue");
  "yellow Pen" = "red Pen" (color="yellow");
  "green Marker" = PEN (size=6 color="green" arrowsize=1);

  "Eraser" = ERASER (size = 75);

  "default" = "red Pen";
  "default"[SHIFT] = "blue Pen";
  "default"[CONTROL] = "yellow Pen";
  "default"[2] = "green Marker";
  "default"[Button3] = "Eraser";
EOF
trap "rm -f '$cfgfile' '$inifile'" EXIT

hey .osd toggle --on -P "" "Screen draw on"
hyprctl keyword decoration:dim_inactive false
# Wayland backend is unreliable on hyprland.
GDK_BACKEND=x11 hey.do gromit-mpx --active
hyprctl keyword decoration:dim_inactive true
hey .osd toggle --off "" "Screen draw off"
