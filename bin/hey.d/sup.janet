#!/usr/bin/env janet
# What's moved on without me.
#
# SYNOPSIS:
#   sup [-H HOST] [-a]
#
# DESCRIPTION:
#   This reads the packages I've installed through my NixOS config, compares
#   them to what's at the latest commits of every input -- nixpkgs, but also
#   niri, emacs-overlay, llm-agents and the rest -- and tells what *would*
#   change if I `hey pull`ed.
#
# OPTIONS:
#   -H, --host HOST @hosts
#     Ask about HOST's configuration instead of this machine's.
#   -a, --all
#     Every package and its version, not only the ones that have moved.

(use hey)
(use sh)

(def- *extract* `
sys:
let
  lib = sys.config.nixpkgs.pkgs.lib;
  nixpkgs = toString sys.config.nixpkgs.pkgs.path;
  outside = path: !(lib.hasPrefix nixpkgs path);
  defs = sys.options.environment.systemPackages.definitionsWithLocations;
  # A definition from outside nixpkgs' own module tree is one of mine...
  mine = lib.concatMap (d: d.value) (lib.filter (d: outside d.file) defs);
  # ...but programs.niri.package is nixpkgs' definition of *my* package.
  foreign = lib.filter (p: outside (p.meta.position or nixpkgs))
                       sys.config.environment.systemPackages;
  user = sys.config.users.users.${sys.config.user.name}.packages or [];
  # for emacsWithPackages, which hides version on its wrapper
  version = p: p.version or p.emacs.version or "";
in lib.listToAttrs
     (map (p: lib.nameValuePair (lib.getName p) (version p)) (mine ++ foreign ++ user))
`)

(defn- versions
  ``The {NAME VERSION} HOST asks for. ARGS go to nix eval.``
  [host & args]
  (json/decode
   ($<_ nix eval --json --no-warn-dirty
        --no-write-lock-file  # no side effects pls
        ,;args
        ,(string (path :home) "#nixosConfigurations." host)
        --apply ,*extract*)))

(defn- upstream-lock []
  (os/mkdir (path :runtime))
  (def lock (path :runtime "sup.lock"))
  # --refresh, or nix hands back whatever it fetched within the last hour
  ($ nix flake update --refresh --output-lock-file ,lock --flake ,(path :home))
  lock)

(defn- moved [have upstream all?]
  (sort (seq [[name version] :pairs have
              :let [new (get upstream name)]
              # An empty version is a wrapper or an env
              :when (or all? (and (not (empty? version))
                                  (not= new version)))]
          [name version new])))

(defn- pad [text width]
  (string text (string/repeat " " (max 0 (- width (length text))))))

(defn- report [rows]
  (def width (max ;(map |(length (in $0 0)) rows)))
  (each [name have upstream] rows
    (echo (string (pad name width) "  "
                  (cond (= have upstream) have
                        (nil? upstream) (string have " -> gone upstream")
                        (string have " -> " upstream))))))

(defcmd sup [_ &opts host [-H --host name] all? [-a --all]]
  (def host (or host (flake :host)))

  (echof :g "> What %s asks for..." host)
  (def have (versions host))
  (echof :g "> What every input has now...")
  (def upstream (versions host "--reference-lock-file" (upstream-lock)))

  (def rows (moved have upstream all?))
  (cond (and (empty? rows) all?)
        (echo :warn "No packages found at all, which can't be right")
        (empty? rows) (echo :check "Nothing has moved on without me.")
        (do (report rows)
          (unless all?
            (echof :g "\n%d of %d behind. `hey pull` to catch up."
                   (length rows) (length (keys have)))))))
