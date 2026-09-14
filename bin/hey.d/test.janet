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
#     hey    -- Run the Janet suite in test/hey through judge.
#     nixos  -- Run the NixOS suite in test/nixos through nix build.
#   * ARGS @test-arg

(use hey)
(use hey/cmd)
(use sh)


# NixOS suites

(defn- nixos-checks [&opt suite]
  (string (path :home) "#checks."
          ($<_ nix eval --raw --impure --expr "builtins.currentSystem")
          ".nixos" (if suite (string ".passthru." suite) "")))

(defn- nixos-suites []
  (string/split
   "\n"
   ($<_ nix eval --raw --no-warn-dirty ,(nixos-checks)
        --apply "d: builtins.concatStringsSep \"\\n\" (builtins.attrNames d.passthru)")))

(defn- run-nixos [args]
  (def suite (first args))
  # Checked up front, because nix's own message for a bad attrpath names three
  # attributes that don't exist and never mentions the suite list.
  (when (and suite (not (index-of suite (nixos-suites))))
    (abort "Unknown NixOS suite: %s (see hey test -l)" suite))
  (echo :g "> Running the NixOS suite...")
  (flush)
  # No --impure and no HEYENV: test/nixos fabricates the `hey` argument itself
  # rather than going through nixosConfigurations, precisely so this stays a
  # pure build. See test/nixos/_lib.nix.
  #
  # A passing nix build says nothing at all, which next to judge's "N passed"
  # reads like the suite never ran, hence the confirmation.
  (if (do? $? nix build --no-link --no-warn-dirty ,(nixos-checks suite))
    (do (echo :check (if suite
                       (string "NixOS suite passed: " suite)
                       "NixOS suites passed"))
        true)
    (abort "NixOS suite failed")))


# Hey suites (Janet)

# Can't list tests with judge, so a filesystem crawl it is.
(defn- hey-suites []
  (sorted (seq [file :in (os/dir (path :test "hey"))
                     :when (string/has-suffix? ".janet" file)
                     :when (not (string/has-prefix? "_" file))]
            (string/no-suffix ".janet" file))))

(defn- run-hey [args]
  (var suite? false)
  (def args (let [suites (hey-suites)]
              (map |(if (index-of $0 suites)
                      (do (set suite? true)
                        (path :test "hey" (string $0 ".janet")))
                      $0)
                   args)))
  (echo :g "> Running the Hey suite...")
  (flush)
  (do? $? judge ,;(if suite? [] [(path :test "hey")]) ,;args))

(defcmd test [_ suite & args &opts list? [-l --list]]
  (case* suite
    nil (if list?
          (do (echo ;(map |(string "hey:" $0) (hey-suites)))
            (echo ;(map |(string "nixos:" $0) (nixos-suites))))
          (and (run-hey []) (run-nixos [])))
    "hey" (if list? (echo ;(hey-suites)) (run-hey args))
    ["nixos" "nix"] (if list? (echo ;(nixos-suites)) (run-nixos args))
    (abort "Unknown suite: %s" suite)))
