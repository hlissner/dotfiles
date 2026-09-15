#!/usr/bin/env janet

(use judge)
(use hey)
(use sh)

(defn- wm-under
  ``What `path :wm` makes of FIXTURE's info.json: the desktop's directory name,
  or "error" if it raised instead of guessing. A subprocess per case, because
  flake/info caches the first info.json it reads for the life of a process.``
  [fixture]
  (with-envvars ["XDG_DATA_HOME" (path :test "hey/lib.d" fixture)]
    ($< janet -e
        "(import hey) (prin (try (hey/path/basename (hey/path :wm)) ([e] \"error\")))")))

(deftest with-envvars
  (test (os/getenv "TEST") nil)
  (with-envvars ["TEST" "123"]
    (test (os/getenv "TEST") "123")
    # A struct drops a nil value, so this used to expand to nothing at all and
    # quietly leave the variable alone.
    (with-envvars ["TEST" nil]
      (test (os/getenv "TEST") nil))
    (test (os/getenv "TEST") "123"))
  (test (os/getenv "TEST") nil))

(deftest path/wm
  # The desktop's name comes from hey.desktop by way of info.json now. It used
  # to come from XDG_CURRENT_DESKTOP, which a tty hasn't got -- so `hey .foo`
  # over there was a janet type error rather than "command not found". A
  # desktop nobody taught me, or none at all, is an error rather than a guess.
  (test (wm-under "hyprland") "hypr")
  (test (wm-under "unknown") "error")
  (test (wm-under "unset") "error"))
