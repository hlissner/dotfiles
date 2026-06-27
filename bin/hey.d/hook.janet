#!/usr/bin/env janet
# Trigger an event.
#
# Hooks are stored in $DOTFILES_HOME/config/$WM/bin/hook.d/*.zsh.
#
# SYNOPSIS:
#   hook HOOK [ARGS...]
#
# RECOGNIZED HOOKS:
#   on-startup
#   on-idle [--{dim,dpms,lock,sleep,resume}]
#   on-sleep
#   on-wakeup
#   on-lock
#   on-unlock
#   on-battery [charging|discharging|*] [ARGS...]
#   on-discarging

(use hey)
(use hey/cmd)
(import hey/vars)

(def- *vars* (vars/new (:dir vars/temp :hook)))

(defn- hooks [hook args]
  (let [wmdir (path :wm "hooks")
        wmdir* (path :wm* "hooks")]
    (each f [(resolve wmdir* "all" (string "--" hook) ;args)
             (resolve wmdir* hook ;args)
             (resolve (path :host "hooks") hook ;args)
             (resolve wmdir "all" (string "--" hook) ;args)
             (resolve wmdir hook ;args)
             ;(map |[$ ;args]
                   (or (ignore-errors
                        (path/files-in (path :data "hooks.d" (string hook ".d"))))
                       []))]
      (when (and f (path/executable? (first f)))
        (yield f)))))

(defcmd hook [_ hook & args &opts force? -f verbose? -v]
  (let [hash [hook ;args]]
    (unless hook
      (abort "No hook specified"))
    (when (and (not force?) (deep= (:get *vars* :last) hash))
      (abort "Redundant hook triggered: %q" hash))
    (os/with-lock (path :runtime "hook.lock")  # don't clobber hooks
      (defer (unless (dryrun?) (:set *vars* :last hash))
        (var c 0)
        (each cmd (coro (hooks hook args))
          (log "Hook: %s" (path/abbrev (first cmd)))
          (echof :g "Running %s..." (path/basename (first cmd)))
          (do? $? ,;cmd)
          (++ c))
        (echof :pass "Triggered %d hook(s) for: %q" c hash)))))
