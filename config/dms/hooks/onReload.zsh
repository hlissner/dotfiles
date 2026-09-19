#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload @dms
#
# DESCRIPTION:
#   Reloads the DankMaterialShell context, regenerating matugen templates and
#   reloading settings set from modules.hyprland.dms, upstream. Evicts any
#   hand-installed plugin that shadows one nix manages.

# DMS prefers ~/.config/DankMaterialShell/plugins over /etc/xdg whenever both
# hold the same plugin, and its UI will cheerfully "update" the former. So a
# hand-installed twin of anything in dms.nix is what I'm actually running, and
# the rev I pin there is theatre until the twin is gone. `dms plugins
# uninstall` finds the user copy first and refuses to touch the system one, so
# it can't take out the wrong twin. Anything without a nix counterpart is left
# alone.
system=/etc/xdg/quickshell/dms-plugins
user=${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins
for plugin in $system/*(N:t); do
  [[ -e $user/$plugin ]] || continue
  echo "DMS: uninstalling $plugin; it shadows the nix-managed one"
  hey.do dms plugins uninstall $plugin
done

# Editing a plugin's QML doesn't reload it -- nothing watches those files -- and
# `plugins reload` takes one id at a time, with no bulk form anywhere in the IPC
# surface. So walk the list. `[disabled]` ones aren't loaded to begin with.
dms ipc call plugins list 2>/dev/null | while read -r plugin state; do
  [[ $state == "[loaded]" ]] || continue
  echo "DMS: reloading plugin $plugin"
  hey.do dms ipc call plugins reload $plugin >/dev/null
done

# This happens to trigger the regeneration of matugen templates as well as
# reloads the declaratively set settings for DMS.
echo "DMS: reloading settings & matugen templates"
systemctl restart --user dms-settings
