#!/usr/bin/env janet
# Operate on the nixos profile.
#
# SYNOPSIS:
#   profile [-u]
#   profile [-r] ls
#   profile [-r] rm [GEN...]
#   profile [-r] diff FROM [TO]
#
# OPTIONS:
#   -r
#     Refresh the cached generation list.
#   -u, --user
#     Target the user profile.
#
# ARGUMENTS:
#   1 COMMAND
#     ls      -- List all system generations.
#     rm      -- Remove a system generation.
#     diff    -- Diff two system generations.
#   * GENERATION @profile-arg
#
# EXAMPLES:
#   hey profile rm 1042
#     Remove system generation 1042.
#   hey profile rm -1
#     Remove the last generation (before the current one).

(use hey)
(use hey/cmd)
(use sh)
(import hey/vars)

(def- *vars* (vars/new (:dir vars/temp :profile)))

(defn- generations [&opt reload?]
  (:cache *vars* :generations
    |(json/decode ($<_ nixos-rebuild list-generations --json)
                  :keywords true)
    reload?))

(defn- generation-at [idx &opt reload?]
  (let [gens (generations reload?)]
    (cond (= idx 0) (find |(get $0 :current) gens)
          (< idx 0) (in gens (+ (length gens) idx))
          (find |(= idx (get $0 :generation)) gens))))

(defn- generation-file [gen &opt exists?]
  (let [path (string/format "%s-%d-link"
                            (path :profile)
                            (get gen :generation))]
    (when (or (not exists?) (path/exists? path))
      path)))

(defn- rm [idx &opt reload?]
  (os/with-lock (path :runtime "profile-rm.lock")
    (if-let [gen (generation-at idx reload?)]
      (do? $ sudo nix-env
           --delete-generations
           --profile ,(path :profile)
           ,(get gen :generation))
      (abort "No system generation: %q" idx))))

(defn- diff [&opt from to]
  (let [from (generation-at (if from (scan-number from) 0))
        to   (generation-at (if to   (scan-number to)   0))
        afile (path :runtime "profile.diff.a")
        bfile (path :runtime "profile.diff.b")]
    (spit afile ($< nix-store -q --references ,(generation-file from) | sort))
    (spit bfile ($< nix-store -q --references ,(generation-file to) | sort))
    (echo :r ;(map |(string "-" $0) ($<_ comm -23 ,afile ,bfile)))
    (echo :g ;(map |(string "+" $0) ($<_ comm -23 ,bfile ,afile)))))


(defcmd profile [_ cmd & args &opts
                 reload? -r
                 user? [-u --user]]
  (case* cmd
    "ls" (echo :json (generations reload?))
    "rm" (each g args (rm (scan-number g) reload?))
    "diff" (diff ;args)
    (echo (path (if user? :profile* :profile)))))
