#!/usr/bin/env janet
# Regression tests for bin/hey.d/sup.janet.
#
# The two evals and the throwaway lock are nix's business and need the
# network. What's mine is the diff between the two answers.

(use judge)
(import hey)

(def- moved
  (get-in (require "../../bin/hey.d/sup") ['moved :value]))

(def- have {"niri" "unstable-2026-10-25-75db0a3"
            "claude-code" "2.1.310"
            "git" "2.56.0"
            "aspell-env" ""
            "mpvc" "1.4"})
(def- upstream {"niri" "unstable-2026-10-26-abc1234"
                "claude-code" "2.1.310"
                "git" "2.57.0"
                "aspell-env" ""})

(deftest sup/moved
  (test (moved have upstream false)
        @[["git" "2.56.0" "2.57.0"]
          # A package nixpkgs dropped is news too, not an error.
          ["mpvc" "1.4" nil]
          ["niri" "unstable-2026-10-25-75db0a3" "unstable-2026-10-26-abc1234"]])

  (deftest "A versionless wrapper or env is only ever noise"
    (test (moved {"aspell-env" ""} {} false) @[]))

  (deftest "-a shows the lot, moved or not, sorted"
    (test (map first (moved have upstream true))
          @["aspell-env" "claude-code" "git" "mpvc" "niri"])
    (test (find |(= (first $) "claude-code") (moved have upstream true))
          ["claude-code" "2.1.310" "2.1.310"])))
