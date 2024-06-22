#!/usr/bin/env janet
# Prints a path to a subarea of my dotfiles.
#
# SYNOPSIS:
#   path [-e] [-a] [AREA] [SEGMENTS...]
#
# OPTIONS:
#   -e
#     Return nothing if resulting path doesn't exist.
#   -d, -f
#     Return nothing if resulting path isn't a directory or file (respectively).
#   -a
#     Abbreviate $HOME/ to ~/ in resulting path.
#
# VALID AREAS:
#   home           $DOTFILES_HOME
#   bin            $DOTFILES_HOME/bin
#   cache          $XDG_CACHE_HOME/hey
#   config         $XDG_CONFIG_HOME/hey
#   data           $XDG_DATA_HOME/hey
#   hosts          $DOTFILES_HOME/hosts
#   host           {hosts}/$HOST/
#   lib            $DOTFILES_HOME/lib
#   modules        $DOTFILES_HOME/modules
#   runtime        $XDG_RUNTIME_DIR/hey
#   state          $XDG_STATE_HOME/hey
#   themes         {modules}/themes
#   theme          {themes}/{THEME}
#   wm             $DOTFILES_HOME/config/{WM}/
#   wm*            $XDG_CONFIG_HOME/{WM}/
#   xdg DIR        $XDG_{DIR}_HOME

(use hey)
(use hey/cmd)

(defn- path-1 [&opt area & args]
  (try (cond (not= area "xdg")
             (path (keyword (or area :home)) ;args)
             (not (get args 1))
             (error "Argument required")
             (path/xdg (keyword (string/ascii-lower (in args 1)))
                       ;(slice args 2)))
       ([err] (abort "%s" err))))

(defcmd path [_ area & args
              &opts
              exists? [-e -f -d]
              abbrev? -a]
  (let [path (path-1 area ;args)]
    (cond (case exists?
            "-e" (not (path/exists? path))
            "-f" (not (path/file? path))
            "-d" (not (path/directory? path)))
          (exit 1)

          abbrev?
          (echo (path/abbrev path))

          (echo path))))
