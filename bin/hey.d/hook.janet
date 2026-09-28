#!/usr/bin/env janet
# Trigger an event.
#
# Hooks live in the directories specified by hey.hookPaths (modules/hey.nix),
# which reach here via hey.info.hooks, so an area this host doesn't enable never
# fires. In each, every executable file named [NN-]HOOK{.janet,.zsh,.sh,} is a
# hook. The list is sorted by NN (50 if absent), and `hey.hookPaths` order is
# the tie-breaker.
#
# An area is the directory owning a hooks/ dir (config/zsh/hooks is zsh), host
# for hosts/$HOST/hooks, or NAME for a hey.hooks fragment (hooks.d/NAME.d).
# @AREA narrows a trigger to that area's handlers.
#
# Will no-op if the hook was already triggered.
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
(use sh)
(import hey/vars)

(def- *vars* (delay (vars/new (:dir (vars/temp) :hook))))

(defn ls
  ``The names in DIR, sorted, as an array.``
  [dir]
  (sorted (or (ignore-errors (os/dir dir)) [])))

(defn- parse-area
  ``Split a leading @AREA off HOOK, returning [AREA HOOK ARGS]. Without the
  sigil, AREA is nil and the arguments are returned untouched.``
  [hook args]
  (if (and hook (string/has-prefix? "@" hook))
    [(string/slice hook 1) (first args) (tuple ;(drop 1 args))]
    [nil hook (tuple ;args)]))

(def- numbered (peg/compile ~(* (<- :d+) "-" (<- (any 1)))))

(defn- hook-name
  "The hook FILE handles: its name, sans NN- and extension."
  [file]
  (let [name (path/no-ext file ;*script-exts*)]
    (or (get (peg/match numbered name) 1) name)))

(defn- order
  "FILE's NN- prefix as a number; 50 without one, same as modules/hey.nix."
  [file]
  (if-let [[nn] (peg/match numbered file)] (scan-number nn) 50))

(defn- runnable?
  "Whether PATH is a handler at all. A non-executable file is not."
  [path]
  (and (path/file? path) (path/executable? path)))

(defn- area-of
  ``The area DIR belongs to: the owner of a hooks/ dir, host for any of
  hosts/*/hooks, or NAME for a hey.hooks fragment's hooks.d/NAME.d.``
  [dir]
  (let [[grandparent parent base] (slice [nil nil ;(string/split "/" (string/trimr dir "/"))] -4)]
    (cond (not= base "hooks") (string/no-suffix ".d" base)
          (= grandparent "hosts") "host"
          parent)))

(defn- dirs
  ``hey.info.hooks, in order; or just AREA's, if given.``
  [&opt area]
  (let [all (or (flake/info :hooks) [])]
    (if area
      (let [dirs (filter |(= (area-of $0) area) all)]
        (if (empty? dirs) (abort "Unknown area: %s" area) dirs))
      all)))

(defn- handlers [dirs hook]
  (->> (seq [[i dir] :pairs dirs
             file :in (ls dir)
             :when (= (hook-name file) hook)
             :let [path (path/join dir file)]
             :when (runnable? path)]
         [(order file) i path])
       (sort)
       (map last)))

(defn- hooks [area hook args]
  (map |[$0 ;args] (handlers (dirs area) hook)))

(defn- all-hooks [&opt area]
  (sorted (distinct (catseq [dir :in (dirs area)] (map hook-name (ls dir))))))

(defn- list-hooks [area hook args]
  (def paths-for |(map first (hooks area $0 args)))
  (if hook
    (echo ;(paths-for hook))
    (each name (all-hooks area)
      (let [paths (paths-for name)]
        (unless (empty? paths)
          (echo name)
          (echo ;(map |(string "  " $0) paths)))))))

(defn- run-hooks
  ``Run every handler for HOOK, unless the last trigger was the same one (and no
  FORCE?). Resolution happens before the lock, so a trigger that can't resolve
  fails with its own error instead of being recorded as the last one.``
  [area hook args force?]
  (let [sig  [;(if area [(string "@" area)] []) hook ;args]
        cmds (hooks area hook args)]
    (when (and (not force?) (deep= (:get (*vars*) :last) sig))
      (abort "Redundant hook triggered: %q" sig))
    (os/with-lock (path :runtime "hook.lock")  # don't clobber hooks
      # Record the trigger even if a handler fails, so a broken one can't be
      # retriggered in a loop.
      (defer (unless (dryrun?) (:set (*vars*) :last sig))
        (def failed @[])
        (with-envvars ["HEY_AREA" area "HEY_HOOK" hook]
          (each cmd cmds
            (def name (path/basename (first cmd)))
            (log "Hook: %s" (path/abbrev (first cmd)))
            (echof :g "Running %s..." name)
            # A failure is still only this handler's problem -- the rest run
            # regardless -- but it used to pass in total silence, and the summary
            # below would cheerfully count it as triggered.
            (unless (do? $? ,;cmd)
              (array/push failed name)
              (echof :warn "Handler failed: %s" name))))
        (echof :pass "Triggered %d hook(s) for: %q" (length cmds) sig)
        (unless (empty? failed)
          (echof :warn "%d of %d failed: %s"
                 (length failed) (length cmds) (string/join failed ", ")))))))

(defcmd hook [_ hook & args &opts force? -f list? [-l --list] verbose? -v]
  (when verbose?
    (setdyn :debug (max 1 (dyn :debug -1))))
  (def [area hook args] (parse-area hook args))
  (cond list?       (list-hooks area hook args)
        (nil? hook) (abort "No hook specified")
        (run-hooks area hook args force?)))
