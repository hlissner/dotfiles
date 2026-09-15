#!/usr/bin/env janet
# Run one or all of the Hey and/or NixOS test suites.
#
# SYNOPSIS:
#   test [SUITE [ARGS...]]
#   test [-l|--list] [SUITE]
#
# OPTIONS:
#   -l [SUITE], --list [SUITE]
#     List SUITE's test suites, instead of running them. If SUITE is omitted,
#     list both.
#
# ARGUMENTS:
#   1 SUITE
#     hey    -- Run the Janet suites in test/* through judge.
#     nixos  -- Run the NixOS suite in test/nixos through nix build.
#   * ARGS @test-arg

(use hey)
(use hey/cmd)
(use sh)


# NixOS suites

(def- *system*
  # Set once; my architecture won't change mid-run
  (delay ($<_ nix eval --raw --impure --expr "builtins.currentSystem")))

(defn- nixos-checks [&opt suite]
  (string (path :home) "#checks." (*system*) ".nixos"
          (if suite (string ".passthru." suite) "")))

(defn- nixos-suites []
  (json/decode
   ($<_ nix eval --json --no-warn-dirty ,(nixos-checks)
        --apply "d: builtins.attrNames d.passthru")))

(defn- run-nixos [args]
  (def suite (first args))
  # Checked up front, because nix's own message for a bad attrpath names three
  # attributes that don't exist and never mentions the suite list.
  (when (and suite (not (index-of suite (nixos-suites))))
    (abort "Unknown NixOS suite: %s (see hey test -l)" suite))
  (echo :g "> Running the NixOS suite...")
  (flush)
  # No --impure and no HEYENV: test/nixos fabricates `specialArgs.hey` itself to
  # keep the test build pure (see test/nixos/_lib.nix)
  (unless (do? $? nix build --no-link --no-warn-dirty ,(nixos-checks suite))
    (abort "NixOS suite failed"))
  # A passing nix build says nothing at all
  (echo :check (if suite
                 (string "NixOS suite passed: " suite)
                 "NixOS suites passed"))
  true)


# Hey suites (Janet)

# Can't list tests with judge, so a filesystem crawl it is. One directory per
# binary under test (test/hey, test/heyops, ...); test/nixos is the other kind
# of suite entirely, and _-prefixed names are shared plumbing.
(defn- hey-dirs []
  (sorted (seq [dir :in (os/dir (path :test))
                :when (not= dir "nixos")
                :when (not (string/has-prefix? "_" dir))
                :when (= :directory (os/stat (path :test dir) :mode))]
            dir)))

(defn- hey-suites []
  (sorted (seq [dir :in (hey-dirs)
                file :in (os/dir (path :test dir))
                :when (string/has-suffix? ".janet" file)
                :when (not (string/has-prefix? "_" file))]
            (string dir "/" (string/no-suffix ".janet" file)))))

(defn- run-hey [args]
  (def suites (hey-suites))
  (def file-of |(if (index-of $0 suites) (path :test (string $0 ".janet"))))
  # A suite name becomes its file; anything else is judge's business
  (def args [;(if (some file-of args) [] (map |(path :test $0) (hey-dirs)))
             ;(map |(or (file-of $0) $0) args)])
  (unless (path/find "judge")
    (echo :g "> Test dependencies are missing; installing them...")
    (os/cd (path :home))  # jpm wants a project.janet to read
    (do? $ jpm deps))
  (echo :g "> Running the Hey suite...")
  (flush)

  # This ordering is important and unintuitive! janet reads the last entry in
  # JANET_PATH as :syspath and searches it ahead of all other entries.
  (with-envvars
    ["JANET_PATH" (string/join [(path :lib)
                                ;(opts (os/getenv "JANET_PATH"))
                                ;(opts (if-let [tree (os/getenv "JANET_TREE")]
                                         (string tree "/lib")))]
                               # shadows lib if :syspath is set
                               ":")]
    (do? $? judge ,;args)))

(defcmd test [_ suite & args &opts list? [-l --list]]
  (case* suite
    nil (if list?
          (do
            (echo ;(map |(string "hey:" $0) (hey-suites)))
            (echo ;(map |(string "nixos:" $0) (nixos-suites))))
          # Short-circuits: no sense waiting on nix if janet already said no.
          (and (run-hey [])
               (run-nixos [])))
    "hey" (if list? (echo ;(hey-suites)) (run-hey args))
    ["nixos" "nix"] (if list? (echo ;(nixos-suites)) (run-nixos args))
    (abort "Unknown suite: %s" suite)))
