
(declare-project
 :name "hey"
 :author "Henrik Lissner <contact@henrik.io>"
 :description "A control center for my dotfiles"
 :license "MIT"
 :url "https://github.com/hlissner/dotfiles"
 :repo "git+https://github.com/hlissner/dotfiles"
 :dependencies [
   {:url "https://github.com/andrewchambers/janet-posix-spawn.git"}
   {:url "https://github.com/andrewchambers/janet-sh.git"}
   {:url "https://github.com/janet-lang/spork.git"}
   {:url "https://github.com/ianthehenry/judge.git"}
   {:url "https://github.com/janet-lang/sqlite3.git"}
 ])

(declare-executable
 :name "hey"
 :entry "bin/hey"
 :install true)

(def *heypath* (string (dyn :modpath) "/hey"))
(def *heybuildpath* (string (dyn :tree) "/build"))

(os/setenv "JANET_BUILDPATH" *heybuildpath*)
(os/mkdir *heybuildpath*)

(task "deploy" ["uninstall" "clean"]
  # jpm won't deploy declared sources before building the executable, so I have
  # to do it manually.
  (def mode (os/stat *heypath* :mode))
  (unless mode
    (shell "ln" "-sv" (abspath "lib/hey") *heypath*))
  (when (or (not mode) (os/getenv "HEYBUILDDEPS"))
    (shell "jpm" "deps"))
  (shell "jpm" "install"
         "--build-type=release"
         "--optimize=3"))

# Default clean rule doesn't seem to see the non-standard JANET_BUILDPATH, so I
# have to reinvent the wheel:
(put-in (getrules) ["clean" :recipe] @[]) # Disable build-in rule
(task "clean" []
  (shell "rm" "-rfv" *heybuildpath* (string (dyn :binpath) "/hey")))

(put-in (getrules) ["test" :recipe] @[]) # Disable build-in tests
(task "test" []
  (protect (shell "judge" "test/hey")))
