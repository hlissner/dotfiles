#!/usr/bin/env janet
# Operate on remote HeyOS-powed hosts.
#
# SYNOPSIS:
#   opts COMMAND [ARGS...]

(use hey)
(use hey/cmd)

# Build flake locally then push it to a remote system.
# [REMOTE...] [-b BUILDER]
(defn- push [])

# Deploy SSH keys from a Bitwarden server.
# [REMOTE...] [-r|--rekey]
(defn- push-keys [])

# Receive keys from stdin (sent via push-keys).
(defn- absorb-keys [])

# Start SSH session on remote.
(defn- ssh [])

# Push and sync flake on remote host.
(defn- sync [])


(defcmd ops [_ & args]
  (not-implemented ;args))
