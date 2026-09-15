
# packages/hey.nix builds hey, so there is no declare-executable or deploy task
# here. Use `jpm install` to produce a development build of hey that will shadow
# the real one. Don't forget to `jpm clean` after `hey sync`ing.

(declare-project
 :name "hey"
 :author "Henrik Lissner <contact@henrik.io>"
 :description "A control center for my dotfiles"
 :license "MIT"
 :url "https://github.com/hlissner/dotfiles"
 :repo "git+https://github.com/hlissner/dotfiles"
 # Mirrors packages/_janet.nix's janetDeps, plus judge.
 :dependencies [
   {:url "https://github.com/andrewchambers/janet-posix-spawn.git"}
   {:url "https://github.com/andrewchambers/janet-sh.git"}
   {:url "https://github.com/janet-lang/spork.git"}
   {:url "https://github.com/janet-lang/sqlite3.git"}
   {:url "https://github.com/ianthehenry/judge.git"}
 ])

(put-in (getrules) ["test" :recipe] @[]) # Disable build-in tests
(task "test" []
  (protect (shell "judge" "test/hey")))
