#!/usr/bin/env janet
# Update one of (or all) HeyOS's inputs.
#
# SYNOPSIS:
#   pull
#   pull [INPUTS]...
#   pull -o [INPUT@REV|INPUT=FLAKE_URI]...
#
# EXAMPLES:
#   hey pull
#     Update all flakes:
#   hey pull waybar 'hypr*'
#     Pull only specific inputs (globs are recognized):
#   hey pull -o waybar@0b6476da32d181ee6b2cabdc5205a46a90521a75 ...
#   hey pull -o waybar=github:aForkOf/Waybar ...
#     A more concise command for repinning inputs.

(use hey)
(use hey/cmd)
(import hey/glob)

(var- *metadata* nil)

(defn metadata []
  (unless *metadata*
    (set *metadata*
         (json/decode ($<_ nix flake metadata --json ,(path :home))
                      :keywords true)))
  *metadata*)

(defcmd pull [_ & args &opts override? [-o --override]]
  (cond
    (empty? args)
    (do
      (echo :g "> Updating all inputs...")
      (do? $ nix flake update --impure ,(path :home)))

    override?
    (let [flake-args @[]]
      (each arg args
        (cond (peg/match '(* :w+ "=") arg)
              (let [[name val] (string/split "=" arg 0 2)]
                (array/push flake-args ["--override-input" name val]))
              (peg/match '(* :w+ "@") arg)
              (let [[name rev] (string/split "@" arg 0 2)
                    input (get-in (metadata) [:locks :nodes (keyword name) :original])]
                (array/push
                 flake-args ["--override-input"
                             name (string/format "%s:%s/%s/%s"
                                                 (input :type)
                                                 (input :owner)
                                                 (input :repo)
                                                 rev)]))
              (abort "Malformed input spec: %s" arg)))
      (when (empty? flake-args)
        (abort "No flakes to override"))
      (do? $ nix flake update --refresh ,;(flatten flake-args) ,(path :home)))

    (let [inputs (keys (get-in (metadata) [:locks :nodes :root :inputs]))
          targets @{}]
      (each m args
        (each i inputs
          (when (glob/match* m (string i))
            (put targets (string i) true))))
      (when (empty? targets)
        (abort "No matching inputs"))
      (echo :g "> Updating matching inputs:")
      (eachk t targets (echof "  - %s" t))
      (do? $ nix flake lock --impure
          --update-input ,;(interpose "--update-input" (keys targets))
          ,(path :home)))))
