#!/usr/bin/env janet
# Move the focused window into a named workspace, or back out of it.
#
# SYNOPSIS:
#   hey wm workspace
#   hey wm workspace move NAME
#
# DESCRIPTION:
#   NAME is one of niri's named workspaces: "home", which
#   modules/wm/niri/default.nix declares, or one `hey wm launch -n` made.
#   Focusing one is a plain focus-workspace in config.kdl (toggled by
#   workspace-auto-back-and-forth); moving a window there and back isn't,
#   because niri has no move-to-previous.
#
#   With no arguments, prints the focused workspace as JSON.
#
# ARGUMENTS:
#   1 COMMAND
#     move     -- Move the focused window to NAME, or back out of it.
#   2 NAME

(use hey)
(import hey/wm)
(import hey/vars)

(defn- move-to [w here ws]
  (def id (string (w :id)))
  (unless (or (ws :name) (= (ws :output) (here :output)))
    (wm/action "move-window-to-monitor" "--id" id (ws :output)))
  (wm/action "move-window-to-workspace" "--window-id" id "--focus" "true"
             (string (or (ws :name) (ws :idx)))))

# "Back" is wherever the window came from, remembered per window id.
(defn- move [name]
  (let [w (or (wm/focused-window) (abort "No focused window"))
        wss (wm/workspaces)
        here (find |(= ($0 :id) (w :workspace)) wss)
        key (keyword "wm.origin." (w :id))]
    (if (= name (get here :name))
      (let [origin (vars/get key)]
        (vars/set key nil)
        (move-to w here (or (find |(= ($0 :id) origin) wss)
                            (abort "Nowhere to move %d back to" (w :id)))))
      (let [there (or (find |(= ($0 :name) name) wss)
                      (abort "No workspace named %s" name))]
        (vars/set key (get here :id))
        (move-to w here there)))))

(defcmd workspace [_ command name]
  (case command
    nil (echo :json (wm/focused-workspace))
    "move" (if name (move name) (usage))
    (usage)))
