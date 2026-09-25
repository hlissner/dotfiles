
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

(defn- janet-sources [& dirs]
  (def out @[])
  (defn walk [dir]
    (each f (os/dir dir)
      (def p (string dir "/" f))
      (case (os/stat p :mode)
        :directory (walk p)
        :file (when (string/has-suffix? ".janet" p) (array/push out p)))))
  (each d dirs (walk d))
  out)

(declare-executable
 :name "hey"
 :entry "bin/hey"
 :install true
 :deps (janet-sources "lib/hey" "bin/hey.d"))

# `jpm clean` rm -rf's ./build, but jpm build cries if the build dir doesn't
# exist, so...
(task "clean" []
  (os/mkdir (dyn :buildpath))
  (os/mkdir (dyn :tree)))

(put-in (getrules) ["test" :recipe] @[]) # Disable build-in tests
(task "test" []
  (protect (shell "judge" "test/hey")))
