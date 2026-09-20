#!/usr/bin/env janet
# What's moved on without me.
#
# SYNOPSIS:
#   sup [-H HOST] [-a]
#
# DESCRIPTION:
#   This reads the packages I've installed through my NixOS config, compares
#   them to what's available at the latest commits of nixos-unstable, and tells
#   what *would* change if I `hey pull`ed.
#
# OPTIONS:
#   -H, --host HOST @hosts
#     Ask about HOST's configuration instead of this machine's.
#   -a, --all
#     Every package and its version, not only the ones that have moved.

(use hey)
(use hey/cmd)
(use sh)

(def- *unstable* "github:NixOS/nixpkgs/nixos-unstable")

# Returned as an attrset rather than a list for easy, unsorted comparison
(def- *extract* `
sys:
let
  lib = sys.config.nixpkgs.pkgs.lib;
  nixpkgs = toString sys.config.nixpkgs.pkgs.path;
  # A definition from outside nixpkgs' own module tree is one of mine.
  mine = d: !(lib.hasPrefix nixpkgs d.file);
  defs = sys.options.environment.systemPackages.definitionsWithLocations;
  sysPkgs = lib.concatMap (d: d.value) (lib.filter mine defs);
  userPkgs = sys.config.users.users.${sys.config.user.name}.packages or [];
  name = p: p.pname or (lib.getName p);
in lib.listToAttrs
     (map (p: lib.nameValuePair (name p) (p.version or "")) (sysPkgs ++ userPkgs))
`)

(defn- versions
  ``The {NAME VERSION} HOST asks for. ARGS go to nix eval.``
  [host & args]
  (json/decode
   ($<_ nix eval --impure --json --no-warn-dirty
        --no-write-lock-file  # no side effects pls
        ,;args
        ,(string (path :home) "#nixosConfigurations." host)
        --apply ,*extract*)))

(defn- pad [text width]
  (string text (string/repeat " " (max 0 (- width (length text))))))

(defn- report [rows]
  (def width (max ;(map |(length (in $0 0)) rows)))
  (each [name have upstream] rows
    (echo (string (pad name width) "  "
                  (cond (= have upstream) have
                        (nil? upstream) (string have " -> gone from unstable")
                        (string have " -> " upstream))))))

(defcmd sup [_ &opts host [-H --host name] all? [-a --all]]
  (os/setenv "HEYENV" (flake/json))
  (def host (or host (flake :host)))

  (echof :g "> What %s asks for..." host)
  (def have (versions host))
  (echof :g "> What nixos-unstable has...")
  (def upstream (versions host "--override-input" "nixpkgs" *unstable*))

  (def rows
    (sort (seq [[name version] :pairs have
                :let [new (get upstream name)]
                # An empty version is a wrapper or an env
                :when (or all? (and (not (empty? version))
                                    (not= new version)))]
            [name version new])))

  (cond (and (empty? rows) all?)
        (echo :warn "No packages found at all, which can't be right")
        (empty? rows) (echo :check "Nothing has moved on without me.")
        (do (report rows)
          (unless all?
            (echof :g "\n%d of %d behind. `hey pull` to catch up."
                   (length rows) (length (keys have)))))))
