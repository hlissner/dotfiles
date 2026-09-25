#!/usr/bin/env janet
# Prints a path to a subarea of my dotfiles.
#
# SYNOPSIS:
#   path [-e|-f|-d] [-a] [AREA] [SEGMENTS...]
#
# OPTIONS:
#   -e | -f | -d
#     Return nothing if the resulting path doesn't exist, isn't a file, or isn't
#     a directory, respectively.
#   -a
#     Abbreviate $HOME/ to ~/ in resulting path.
#
# ARGUMENTS:
#   1 AREA
#     home           $DOTFILES_HOME
#     assets         {home}/assets
#     bin            {home}/bin
#     cache          $XDG_CACHE_HOME/hey
#     config         {home}/config
#     data           $XDG_DATA_HOME/hey
#     hosts          {home}/hosts
#     host           {hosts}/$HOST
#     lib            {home}/lib
#     modules        {home}/modules
#     runtime        $XDG_RUNTIME_DIR/hey
#     state          $XDG_STATE_HOME/hey
#     test           {home}/test
#     wm             {config}/$WM
#     wm*            $XDG_CONFIG_HOME/$WM
#     profile        The system nix profile.
#     profile*       The user nix profile.
#     xdg            $XDG_{DIR}_HOME, where DIR is the next segment.
#   * SEGMENT @path-segment

(use hey)

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
