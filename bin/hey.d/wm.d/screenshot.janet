#!/usr/bin/env janet
# Capture a screenshot to clipboard.
#
# SYNOPSIS:
#   hey wm screenshot [-o FILE] [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Captures with grim (selecting through `hey wm slurp`), squeezes it through
#   pngquant, and copies it to the clipboard. For graphics, `noctalia msg
#   annotate` draws on the screen first.
#
# OPTIONS:
#   -o, --output FILE @files
#     Write the PNG to FILE (- for stdout) and say nothing, instead of copying
#     it to the clipboard. For scripts that want the image rather than my
#     clipboard, like `hey wm ocr`.
#
# ARGUMENTS:
#   1 TARGET
#     all       -- Capture all outputs combined
#     full      -- Capture the focused output
#     last      -- Capture the previous selection.
#     region    -- Select a region interactively (the default).
#     window    -- Select selected window.
#     output    -- Select a monitor.

(use hey)
(use sh)
(import hey/wm)
(import hey/sys)

(defn capture
  "TARGET as pngquant'ed PNG bytes, or nil when the selection was cancelled."
  [target]
  (default target "region")
  (def args
    (case target
      "all" []
      "full" ["-o" (get (find |($0 :focused) (wm/outputs)) :name)]
      (when-let [geom (wm/select target)] ["-g" geom])))
  (def png @"")
  (when (and args ($? grim ,;args - | pngquant --strip -s 10 - > ,png))
    png))

(defcmd screenshot [_ target &opts outfile [-o --output outfile]]
  (each dep ["grim" "pngquant"]
    (unless (path/find dep) (abort "Required dependency not met: %s" dep)))
  (unless (index-of (or target "region") ["all" "full" "last" "region" "window" "output"])
    (usage))
  (if-let [png (capture target)]
    (cond
      (= outfile "-") (file/write stdout png)
      outfile (spit outfile png)
      (let [preview (path :runtime "screenshot.png")]
        (os/mkdir (path :runtime))
        (spit preview png)
        (sys/yank png :type "image/png")
        # A notification, not a toast: the OSD can't show the preview.
        (sys/notify "Copied to clipboard" :title "Screenshot captured" :icon preview)))
    (do (sys/toast :warn "Aborted" :icon "camera-off" :inactive true)
        (exit 1))))
