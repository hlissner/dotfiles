#!/usr/bin/env janet
# Trigger an event.
#
# A hook is scoped to an area: a directory under config/ that owns a hooks/
# subdirectory (plus the reserved area "host", for hosts/$HOST/hooks). Without
# an area, every area is triggered, ordered by the active window manager first,
# then alphabetically.
#
# Executes each of the following, in this order. NAME means the first of
# NAME.janet, NAME.zsh, NAME.sh or NAME that exists:
#
# - ~/.config/$AREA/hooks/all --$HOOK
# - ~/.config/$AREA/hooks/$HOOK
# - hosts/$HOST/hooks/$HOOK
# - config/$AREA/hooks/all --$HOOK
# - config/$AREA/hooks/$HOOK
# - $XDG_DATA_HOME/hey/hooks.d/$HOOK.d/*
#
# The last has no area, so it is skipped when one is given.
#
# Will no-op if the hook was already triggered.
#
# Run hey hook -l for a list of all known hooks on your system.
#
# SYNOPSIS:
#   hook [-f] [-v] [@AREA] HOOK [ARGS...]
#   hook [-l|--list] [@AREA] [HOOK [ARGS...]]
#
# OPTIONS:
#   -f
#     Trigger the hook even if it is redundant.
#   -l [HOOK], --list [HOOK]
#     List the scripts that would be run, instead of running them. Without a
#     HOOK, list them for every known hook, grouped by hook.
#   -v
#     Be verbose; logs the path of each handler as it runs. Equivalent to
#     hey -? for this command alone.
#
# ARGUMENTS:
#   1 HOOK @hooks
#   ** ARGS @hook-arg

(use hey)
(use hey/cmd)
(use sh)
(import hey/vars)

(def- *vars* (delay (vars/new (:dir (vars/temp) :hook))))

(defn- ls
  "The names in DIR, or nothing if it can't be read."
  [dir]
  (or (ignore-errors (os/dir dir)) []))

(defn- ls-in
  "Like ls, but as absolute paths."
  [dir]
  (map |(path/join dir $0) (ls dir)))

(defn- hook-names-in
  "The hook each script in DIR handles; its filename, sans extension."
  [dir]
  (map |(path/no-ext $0 ;*script-exts* ".d") (ls dir)))

(defn- runnable?
  ``Whether CMD is a [SCRIPT ARGS...] we can execute. resolve yields nil when it
  finds nothing, and a match that isn't an executable file is no handler.``
  [cmd]
  (when-let [script (and cmd (first cmd))]
    (and (path/file? script) (path/executable? script))))

(defn parse-area
  ``Split a leading @AREA off HOOK, returning [AREA HOOK ARGS]. Without the
  sigil, AREA is nil and the arguments are returned untouched.``
  [hook args]
  (if (and hook (string/has-prefix? "@" hook))
    [(string/slice hook 1) (first args) (tuple ;(drop 1 args))]
    [nil hook (tuple ;args)]))

(defn sort-areas
  ``Order area NAMES with WM first, the rest alphabetically, then host, which is
  always known because it names hosts/$HOST/hooks.``
  [names &opt wm]
  (let [names (distinct (filter |(not= $0 "host") names))]
    [;(filter |(= $0 wm) names)
     ;(sorted (filter |(not= $0 wm) names))
     "host"]))

(defn- areas
  ``Every area with a hooks/ directory, in run order; or only AREA, if given and
  known.``
  [&opt area]
  (let [dirs  (filter |(path/directory? (path :config $0 "hooks")) (ls (path :config)))
        wm    (ignore-errors (path/basename (path :wm)))
        names (sort-areas dirs wm)]
    (cond (nil? area) names
          (index-of area names) [area]
          (abort "Unknown area: %s" area))))

(defn- area-dirs
  ``The hooks/ directories of NAMES, grouped as [LIVE HOST REPO]. The host's
  hooks aren't user-editable elsewhere, so it has no live counterpart.``
  [names]
  (let [cfgs (filter |(not= $0 "host") names)]
    [(map |(path/xdg :config $0 "hooks") cfgs)
     (if (index-of "host" names) [(path :host "hooks")] [])
     (map |(path :config $0 "hooks") cfgs)]))

(defn- hooks
  "The [SCRIPT ARGS...] commands HOOK resolves to, in the order they run."
  [area hook args]
  (let [[live host repo] (area-dirs (areas area))
        # An area's `all` handler runs ahead of its handler for this hook.
        resolve-in |[(resolve $0 "all" (string "--" hook) ;args)
                     (resolve $0 hook ;args)]
        # Third party handlers (see modules/hey.nix) belong to no area.
        third-party (if area [] (ls-in (path :data "hooks.d" (string hook ".d"))))]
    (filter runnable?
            [;(catseq [dir :in live] (resolve-in dir))
             ;(map |(resolve $0 hook ;args) host)
             ;(catseq [dir :in repo] (resolve-in dir))
             ;(map |[$0 ;args] third-party)])))

(defn- all-hooks
  "The name of every hook that has a handler anywhere."
  [&opt area]
  (let [[live host repo] (area-dirs (areas area))
        names (catseq [dir :in [;live ;host ;repo]] (hook-names-in dir))]
    (sorted
     (distinct
      [;(filter |(not= $0 "all") names)  # fallthrough handler for all hooks
       ;(if area [] (hook-names-in (path :data "hooks.d")))]))))

(defn- list-hooks
  ``Print the handlers HOOK would run; or, without one, every hook's, indented
  under its name.``
  [area hook args]
  (def paths-for |(map first (hooks area $0 args)))
  (if hook
    (echo ;(paths-for hook))
    (each name (all-hooks area)
      (let [paths (paths-for name)]
        (unless (empty? paths)
          (echo name)
          (echo ;(map |(string "  " $0) paths)))))))

(defn- run-hooks
  ``Run every handler for HOOK, unless the last trigger was the same one (and
  not FORCE?). Resolution happens before the lock, so a trigger that can't
  resolve fails with its own error instead of being recorded as the last one.``
  [area hook args force?]
  (let [sig  [;(if area [(string "@" area)] []) hook ;args]
        cmds (hooks area hook args)]
    (when (and (not force?) (deep= (:get (*vars*) :last) sig))
      (abort "Redundant hook triggered: %q" sig))
    (os/with-lock (path :runtime "hook.lock")  # don't clobber hooks
      # Record the trigger even if a handler fails, so a broken one can't be
      # retriggered in a loop.
      (defer (unless (dryrun?) (:set (*vars*) :last sig))
        (each cmd cmds
          (log "Hook: %s" (path/abbrev (first cmd)))
          (echof :g "Running %s..." (path/basename (first cmd)))
          (do? $? ,;cmd))
        (echof :pass "Triggered %d hook(s) for: %q" (length cmds) sig)))))

(defcmd hook [_ hook & args &opts force? -f list? [-l --list] verbose? -v]
  (when verbose?
    (setdyn :debug (max 1 (dyn :debug -1))))
  (def [area hook args] (parse-area hook args))
  (cond list?       (list-hooks area hook args)
        (nil? hook) (abort "No hook specified")
        (run-hooks area hook args force?)))
