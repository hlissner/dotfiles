#!/usr/bin/env janet
# Run a program and pin its windows to a workspace, however long it dawdles.
#
# SYNOPSIS:
#   hey wm launch [--here|--empty] [-n NAME] -a APPID -- COMMAND [ARGS...]
#
# DESCRIPTION:
#   niri opens a window on whatever workspace is focused when it finally maps,
#   not where it was launched from; Steam takes ten seconds to get there and
#   I've long moved on. The activation token niri hands a spawned command only
#   decides focus, and dies after ten seconds anyway. What niri does honour is
#   open-on-workspace by *name*, resolved when the window first configures. So:
#   name the target workspace if it has none, write a window-rule for APPID
#   into ~/.config/niri/launch.kdl (niri.nix includes it last), reload, run
#   COMMAND, and undo all of it when COMMAND exits. The rule stays up that long
#   because Steam keeps opening windows -- splash, main, friends, games -- for
#   as long as it runs.
#
# OPTIONS:
#   --here
#     The workspace focused right now. The default.
#   --empty
#     The empty workspace at the bottom of the focused output.
#   -n, --name NAME
#     What to call an unnamed target while COMMAND runs; the bar will show it.
#     Defaults to COMMAND's basename.
#   -a, --app-id APPID
#     The regex the rule matches app-id against, e.g. '^steam$'.
#
# ARGUMENTS:
#   ** COMMAND @commands

(use hey)
(import hey/wm)
(import hey/vars)

(def- prefix "wm.launch.")

(defn- target [where]
  (def wss (wm/workspaces))
  (def here (or (find |($0 :focused) wss) (abort "No focused workspace")))
  (case where
    :here here
    :empty (or (last (sort-by |($0 :idx)
                              (filter |(and (= ($0 :output) (here :output))
                                            ($0 :empty)
                                            (nil? ($0 :name)))
                                      wss)))
               (abort "No empty workspace on %s" (here :output)))))

# One var per launch in flight and the file is all of them, so two launches
# don't clobber each other's rule and the last one out clears the file.
(defn- sync-rules []
  (def file (path :wm* "launch.kdl"))
  (def rules
    (seq [key :in (vars/list)
          :when (string/has-prefix? prefix key)
          :let [r (vars/get key)]
          :when r]
      (string/format "window-rule {\n    match app-id=r#\"%s\"#\n    open-on-workspace \"%s\"\n}\n"
                     (r :app-id) (r :workspace))))
  (if (empty? rules)
    (when (path/file? file) (os/rm file))
    (do (os/mkdir (path/dirname file))
        (spit file (string/join rules "\n"))))
  (wm/action "load-config-file"))

(defcmd launch [_ & command &opts
                here? [--here]
                bottom? [--empty]
                name [-n --name name]
                app-id [-a --app-id app-id]]
  (when (or (empty? command) (and here? bottom?)) (usage))
  (unless app-id (abort "An --app-id regex is required"))
  (def ws (target (if bottom? :empty :here)))
  (def name (or (ws :name) name (path/basename (first command))))
  # A workspace already called NAME is a launch in flight (Steam is up, and
  # this `steam` will just poke it and return), so its windows belong there,
  # and it isn't mine to unname.
  (def taken? (and (nil? (ws :name))
                   (find |(= ($0 :name) name) (wm/workspaces))))
  (def owned? (and (nil? (ws :name)) (not taken?)))
  (when owned?
    (wm/action "set-workspace-name" "--workspace" (string (ws :idx)) name))
  (def key (keyword prefix (os/getpid)))
  (vars/set key {:app-id app-id :workspace name})
  (sync-rules)
  # Cleanup even when the command can't be spawned, or the rule outlives it
  # until logout.
  (def code
    (defer (do (vars/set key nil)
               (sync-rules)
               (when owned?
                 (wm/action "unset-workspace-name" name)))
      (os/execute command :p)))
  (exit code))
