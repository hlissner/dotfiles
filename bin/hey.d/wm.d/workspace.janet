#!/usr/bin/env janet
# Toggle a named workspace, or move the focused window into it and back.
#
# SYNOPSIS:
#   hey wm workspace
#   hey wm workspace toggle NAME
#   hey wm workspace move NAME
#
# DESCRIPTION:
#   NAME is media or scratchpad: hyprland's special workspaces, niri's named
#   ones. Under hyprland this defers to hyprland.lua's own dispatchers, so a
#   keybind and the bar agree on what a toggle is. Under niri a toggle is
#   focus-workspace, or focus-workspace-previous when NAME is already up.
#
#   With no arguments, prints the focused workspace as JSON.
#
# ARGUMENTS:
#   1 COMMAND
#     toggle   -- Go to NAME, or back to where I was if NAME is focused.
#     move     -- Move the focused window to NAME, or back out of it.
#   2 NAME
#     media
#     scratchpad

(use hey)
(import hey/wm)
(import hey/vars)

# hyprland.lua's names: one global special:media, and a per-monitor pad.
(def- hypr-toggle
  {"media"      `hey.dsp.scratchpad("media")()`
   "scratchpad" `hey.dsp.local_scratchpad("pad")()`})
(def- hypr-move
  {"media"      `hey.dsp.move_to_workspace_or_back("media")()`
   "scratchpad" `hey.dsp.move_to_workspace_or_back("pad", hey.dsp.move_to_local_scratchpad("pad"))()`})

(defn- toggle [name]
  (case (wm)
    :hypr (wm/action :hypr {:eval (get hypr-toggle name)})
    :niri (if (= name (get (wm/focused-workspace) :name))
            (wm/action :niri ["focus-workspace-previous"])
            (wm/action :niri ["focus-workspace" name]))))

(defn- move-to [window ws]
  (wm/action :niri ["move-window-to-workspace" "--window-id" (string (window :id))
                    "--focus" "true" (string ws)]))

# "Back" is wherever the window came from. niri has no move-to-previous, so
# the origin is remembered per window id in a session var on the way in, and
# the output's first unnamed workspace stands in when there's nothing to
# remember (a window that opened on the scratchpad, say).
(defn- move [name]
  (case (wm)
    :hypr (wm/action :hypr {:eval (get hypr-move name)})
    :niri (let [w (or (wm/focused-window) (abort "No focused window"))
                wss (wm/workspaces)
                here (find |(= ($0 :id) (w :workspace)) wss)
                key (keyword "wm.origin." (w :id))]
            (if (= name (get here :name))
              (let [origin (vars/get key)
                    back (or (find |(= ($0 :id) origin) wss)
                             (find |(and (= ($0 :output) (get here :output)) (nil? ($0 :name))) wss)
                             (abort "Nowhere to move %s back to" (w :id)))]
                (vars/set key nil)
                (move-to w (back :id)))
              (do (vars/set key (get here :id))
                  (move-to w name))))))

(defcmd workspace [_ command name]
  (case command
    nil (echo :json (wm/focused-workspace))
    "toggle" (if (get hypr-toggle name) (toggle name) (usage))
    "move" (if (get hypr-move name) (move name) (usage))
    (usage)))
