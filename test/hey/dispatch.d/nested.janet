#!/usr/bin/env janet
# A dispatcher with nested rulesets.
#
# SYNOPSIS:
#   nested COMMAND [ARGS...]

(use hey)
(import ./gated)

(defn- one [& args] (echo "one" ;args))

(defn main [_ & args]
  (dispatch [:static {:doc "A fixed ruleset." :rules [:one one]}
             :gated  gated/gated]
            ;args))
