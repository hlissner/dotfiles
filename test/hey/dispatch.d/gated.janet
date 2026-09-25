#!/usr/bin/env janet
# A ruleset only some machines may use.
#
# SYNOPSIS:
#   nested gated COMMAND

(use hey)

(defn- one [& args] (echo "one" ;args))

(def gated
  {:rules (fn [& _]
            (when (os/getenv "GATED")
              (abort "gated"))
            [:one one
             :two {:doc "Two." :eval |[one ;$&]}])})
