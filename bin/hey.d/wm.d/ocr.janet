#!/usr/bin/env janet
# Copy text out of a region of the screen, via OCR.
#
# SYNOPSIS:
#   hey wm ocr [-l LANG] [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Screenshots a region (with `hey wm screenshot`), runs it through tesseract,
#   and sends the result to the clipboard. imagemagick and tesseract come from
#   cached-nix-shell on demand.
#
# OPTIONS:
#   -l, --lang LANG
#     The tesseract language to recognize, or several joined by "+"
#     (e.g. eng+jpn). Defaults to eng.
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
(import hey/sys)
(import ./screenshot)

(defcmd ocr [_ target &opts lang [-l --lang lang]]
  (each dep ["cached-nix-shell" "wl-copy"]
    (unless (path/find dep) (abort "Required dependency not met: %s" dep)))
  (default lang "eng")
  # It lands in a nix expression below, so it doesn't get to be arbitrary.
  (unless (peg/match (peg! '(* (some (+ :w "_")) (any (* "+" (some (+ :w "_")))) -1)) lang)
    (abort "Not a tesseract language: %s" lang))
  # Unoverridden, nixpkgs' tesseract carries every language it has ever heard
  # of: a 1.1G closure to read a tooltip. Take only what I asked for (112M).
  (def pkg (fmt "tesseract.override { enableLanguages = [ %s ]; }"
                (string/join (map |(fmt "%q" $0) (string/split "+" lang)) " ")))

  # A cancelled selection is not an error worth announcing twice.
  (def png (or (screenshot/capture target) (exit 1)))
  (def img (path :runtime "ocr.png"))
  (os/mkdir (path :runtime))
  (spit img png)
  (defer (os/rm img)
    (sys/toast :info "Processing capture..." :icon "text-scan-2")
    (def text @"")
    (unless ($? cached-nix-shell -p ,pkg -p imagemagick --run
                ,(fmt `magick png:'%s' -colorspace Gray -resize 300%% -sharpen 0x1 png:- |
                       tesseract --dpi 300 - - -l '%s'` img lang)
                > ,text)
      (exit 1))
    # tesseract ends every page with a form feed.
    (def text (string/replace-all "\f" "" text))
    (when (empty? (string/trim text))
      (sys/toast :warn "OCR found no text there" :icon "text-scan-2" :inactive true)
      (exit 1))
    (sys/yank text)
    (def preview (string/trim (string/join (string/split " " (string/replace-all "\n" " " text)) " ")))
    # A notification, not a toast: the preview is the point, and it's a body.
    (sys/notify (if (> (length preview) 120) (string (slice preview 0 119) "…") preview)
                :title (fmt "Copied %d characters" (length text))
                :icon "text-scan-2")))
